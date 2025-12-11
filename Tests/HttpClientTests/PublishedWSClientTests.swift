import Combine
import Foundation
import Testing
@testable import HttpClient

@Suite struct PublishedWSClientTests {
    @Test func sendFailsWhenNotConfigured() async {
        let delegate = PublishedWSClient.UrlSessionDelegate(logger: TestLogger())
        let client = PublishedWSClient(
            logger: TestLogger(),
            delegate: delegate,
            webSocketTaskFactory: { _, _, _ in fatalError("not used") },
            keepAlivePublisherFactory: { _ in Empty().eraseToAnyPublisher() }
        )

        let result = await client.send("hi")
        switch result {
        case let .failure(.failedToSend_NotConnected(msg)):
            switch msg {
            case let .string(string):
                #expect(string == "hi")
            default:
                #expect(Bool(false), "Expected string payload")
            }
        default:
            #expect(Bool(false), "Expected notConfigured failure")
        }
    }

    @Test func keepAliveSendsPingWhenConnected() async throws {
        let ticks = PassthroughSubject<Date, Never>()
        let webSocketTask = MockWebSocketTask()
        webSocketTask.enqueue(.success(.string("boot")))

        let delegate = PublishedWSClient.UrlSessionDelegate(logger: TestLogger())
        let client = PublishedWSClient(
            logger: TestLogger(),
            delegate: delegate,
            webSocketTaskFactory: { _, _, _ in webSocketTask },
            keepAlivePublisherFactory: { _ in ticks.eraseToAnyPublisher() }
        )

        let config = PublishedWSClient.Config(
            pingInterval: 1,
            reconnectInterval: 0,
            sessionConfig: .ephemeral,
            urlPath: "wss://example.com/socket",
            headers: { [:] }
        )

        _ = await client.configure(with: config)
        _ = await client.connect()

        delegate.status = .connected
        ticks.send(Date())
        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(webSocketTask.pingCount == 1)
        await client.disconnect()
    }

    @Test func reconnectsAfterTransportError() async throws {
        let delegate = PublishedWSClient.UrlSessionDelegate(logger: TestLogger())

        let first = MockWebSocketTask()
        let second = MockWebSocketTask()
        first.enqueue(.failure(MockWebSocketTask.StubError.transport))

        let queue = SocketQueue([first, second])
        let factory: PublishedWSClient.WebSocketTaskFactory = { _, _, _ in
            queue.next()
        }

        let client = PublishedWSClient(
            logger: TestLogger(),
            delegate: delegate,
            webSocketTaskFactory: factory,
            keepAlivePublisherFactory: { _ in Empty().eraseToAnyPublisher() }
        )

        let config = PublishedWSClient.Config(
            pingInterval: 60,
            reconnectInterval: 0,
            sessionConfig: .ephemeral,
            urlPath: "wss://example.com/ws",
            headers: { [:] }
        )

        let publisher = await client.msgPublisher
        var receivedValues: [Result<Data?, IPublishedWSClient.Err>] = []
        let cancellable = publisher.sink { value in receivedValues.append(value) }

        _ = await client.configure(with: config)
        _ = await client.connect()
        delegate.status = .connected

        for _ in 0..<10 where queue.producedCount < 2 {
            try await Task.sleep(nanoseconds: 100_000_000)
        }

        #expect(queue.producedCount == 2)
        #expect(first.cancelCallCount == 1)
        #expect(second.resumeCallCount == 1)

        let firstValue = try #require(receivedValues.first)
        switch firstValue {
        case let .failure(.transportError(cause, status)):
            #expect(cause is MockWebSocketTask.StubError)
            #expect(status == .connected || status == .initial)
        default:
            #expect(Bool(false), "Expected transportError, got \(String(describing: firstValue))")
        }

        cancellable.cancel()
        await client.disconnect()
    }

    @Test func configureFailsWhenConnected() async {
        let delegate = PublishedWSClient.UrlSessionDelegate(logger: TestLogger())
        let webSocketTask = MockWebSocketTask()
        webSocketTask.enqueue(.success(.string("hold")))

        let client = PublishedWSClient(
            logger: TestLogger(),
            delegate: delegate,
            webSocketTaskFactory: { _, _, _ in webSocketTask },
            keepAlivePublisherFactory: { _ in Empty().eraseToAnyPublisher() }
        )

        let config = PublishedWSClient.Config(
            pingInterval: 5,
            reconnectInterval: 0,
            sessionConfig: .ephemeral,
            urlPath: "wss://example.com/socket",
            headers: { [:] }
        )

        _ = await client.configure(with: config)
        _ = await client.connect()
        delegate.status = .connected

        let result = await client.configure(with: config)
        switch result {
        case let .failure(.failedToBuildRequest(forUrlPath)):
            #expect(forUrlPath == config.urlPath)
        default:
            #expect(Bool(false), "Expected configure failure while connected")
        }

        await client.disconnect()
    }

    @Test func configEqualityAndDefaults() {
        let headers: PublishedWSClient.HeadersResolver = { [:] }
        let configA = PublishedWSClient.Config(urlPath: "wss://example.com", headers: headers)
        let configB = PublishedWSClient.Config(urlPath: "wss://example.com", headers: headers)
        let configC = PublishedWSClient.Config(pingInterval: 5, reconnectInterval: 2, urlPath: "wss://example.com", headers: headers)

        #expect(configA == configA)
        #expect(configA.urlPath == configB.urlPath)
        #expect(configA != configC)
        #expect(configA.sessionConfig.timeoutIntervalForRequest == 120)
        #expect(configA.sessionConfig.timeoutIntervalForResource == 604800)
    }

    @Test func delegateTransitionsStatuses() async throws {
        let delegate = PublishedWSClient.UrlSessionDelegate(logger: TestLogger())
        #expect(delegate.status == .initial)
        #expect(delegate.status.isConnected == false)

        let url = try #require(URL(string: "wss://example.com/socket"))
        let task = URLSession(configuration: .ephemeral).webSocketTask(with: url)

        delegate.urlSession(URLSession.shared, webSocketTask: task, didOpenWithProtocol: nil)
        #expect(delegate.status == .connected)
        #expect(delegate.status.debugDescription == "connected")

        delegate.urlSession(URLSession.shared, webSocketTask: task, didCloseWith: .normalClosure, reason: nil)
        #expect(delegate.status.isConnected == false)
        #expect(delegate.status.debugDescription.contains("disconnected"))
    }
}

final class MockWebSocketTask: WebSocketTasking, @unchecked Sendable {
    enum StubError: Error {
        case transport
    }

    private(set) var closeCode: URLSessionWebSocketTask.CloseCode = .invalid
    private var iterator: AsyncStream<Result<URLSessionWebSocketTask.Message, Error>>.Iterator
    private let continuation: AsyncStream<Result<URLSessionWebSocketTask.Message, Error>>.Continuation

    private(set) var resumeCallCount = 0
    private(set) var cancelCallCount = 0
    private(set) var lastCancelCode: URLSessionWebSocketTask.CloseCode?
    private(set) var sentMessages: [URLSessionWebSocketTask.Message] = []
    var sendError: Error?
    private(set) var pingCount = 0
    var pingErrors: [Error?] = []

    init() {
        var capturedContinuation: AsyncStream<Result<URLSessionWebSocketTask.Message, Error>>.Continuation!
        let stream = AsyncStream<Result<URLSessionWebSocketTask.Message, Error>> { continuation in
            capturedContinuation = continuation
        }
        guard let continuation = capturedContinuation else {
            fatalError("AsyncStream continuation unavailable")
        }
        self.continuation = continuation
        self.iterator = stream.makeAsyncIterator()
    }

    func enqueue(_ result: Result<URLSessionWebSocketTask.Message, Error>) {
        continuation.yield(result)
    }

    func finish() {
        continuation.finish()
    }

    func resume() {
        resumeCallCount += 1
    }

    func cancel(with closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        cancelCallCount += 1
        lastCancelCode = closeCode
        self.closeCode = closeCode
        continuation.finish()
    }

    func send(_ message: URLSessionWebSocketTask.Message) async throws {
        sentMessages.append(message)
        if let sendError {
            throw sendError
        }
    }

    func sendPing(pongReceiveHandler: @escaping (Error?) -> Void) {
        pingCount += 1
        let error = pingErrors.isEmpty ? nil : pingErrors.removeFirst()
        pongReceiveHandler(error)
    }

    func receive() async throws -> URLSessionWebSocketTask.Message {
        guard let result = await iterator.next() else {
            throw StubError.transport
        }

        switch result {
        case let .success(msg):
            return msg
        case let .failure(error):
            throw error
        }
    }
}

final class SocketQueue: @unchecked Sendable {
    private var tasks: [MockWebSocketTask]
    private var produced = 0

    init(_ tasks: [MockWebSocketTask]) {
        self.tasks = tasks
    }

    func next() -> MockWebSocketTask {
        defer { produced += 1 }
        guard !tasks.isEmpty else { fatalError("No more tasks in queue") }
        return tasks.removeFirst()
    }

    var producedCount: Int { produced }
}
