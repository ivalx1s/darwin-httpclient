import Foundation
import Testing
@testable import HttpClient

@Suite struct WSClientTests {
    @Test func connectStreamsIncomingMessages() async throws {
        let task = MockWebSocketTask()
        task.enqueue(.success(.string("hello")))
        task.enqueue(.success(.data(Data("world".utf8))))

        let client = WSClient(
            urlSession: URLSession(configuration: .ephemeral),
            logger: TestLogger(),
            webSocketTaskFactory: { request, _ in
                #expect(request.url?.absoluteString == "wss://example.com/socket")
                return task
            }
        )

        let result = await client.connect(to: "wss://example.com/socket", with: [:])
        guard case let .success(stream) = result else {
            #expect(Bool(false), "Expected successful connect")
            return
        }

        var iterator = stream.makeAsyncIterator()
        let first = try #require(await iterator.next())
        switch first {
        case let .success(data):
            #expect(String(decoding: data, as: UTF8.self) == "hello")
        case let .failure(error):
            #expect(Bool(false), "Unexpected failure \(error)")
        }

        let second = try #require(await iterator.next())
        switch second {
        case let .success(data):
            #expect(String(decoding: data, as: UTF8.self) == "world")
        case let .failure(error):
            #expect(Bool(false), "Unexpected failure \(error)")
        }

        await client.disconnect()
    }

    @Test func sendFailsWhenNotConnected() async {
        let client = WSClient(
            urlSession: URLSession(configuration: .ephemeral),
            logger: TestLogger(),
            webSocketTaskFactory: { _, _ in MockWebSocketTask() }
        )

        let result = await client.send("ping")
        switch result {
        case let .failure(error):
            switch error {
            case let .failedToSend_NotConnected(msg):
                if case let .string(value) = msg {
                    #expect(value == "ping")
                }
            default:
                #expect(Bool(false), "Unexpected error \(error)")
            }
        case .success:
            #expect(Bool(false), "Expected send failure while disconnected")
        }
    }

    @Test func receiveFailureDisconnects() async throws {
        let task = MockWebSocketTask()
        task.enqueue(.failure(MockWebSocketTask.StubError.transport))

        let client = WSClient(
            urlSession: URLSession(configuration: .ephemeral),
            logger: TestLogger(),
            webSocketTaskFactory: { _, _ in task }
        )

        let result = await client.connect(to: "wss://example.com/socket", with: [:])
        guard case let .success(stream) = result else {
            #expect(Bool(false), "Expected successful connect")
            return
        }

        var iterator = stream.makeAsyncIterator()
        let first = try #require(await iterator.next())
        switch first {
        case .success:
            #expect(Bool(false), "Expected failure result")
        case let .failure(error):
            switch error {
            case .disconnected:
                #expect(task.cancelCallCount >= 1)
            default:
                #expect(Bool(false), "Unexpected error \(error)")
            }
        }

        await client.disconnect()
    }
}
