import Combine
import Foundation
import Testing
@testable import HttpClient

@Suite struct PublishedStubbableWSClientTests {
    typealias Err = IPublishedWSClient.Err
    
    @Test func stubbedSendPublishesIncomingMessage() async throws {
        let baseClient = MockPublishedWSClient()
        let stubbable = PublishedStubbableWSClient(client: baseClient, logger: TestLogger())

        let outgoing = try #require(
            PublishedStubbableWSClient.Stub.OutgoingMsg(
                outgoingMsgData: Data(#"{"action":"ping","ts":1}"#.utf8),
                ignoringKeys: ["ts"],
                ignoringDeep: true
            )
        )
        let stub = try #require(
            PublishedStubbableWSClient.Stub(
                outgoingMsg: outgoing,
                incomingMsgData: Data("stubbed".utf8)
            )
        )
        await stubbable.setStubs([stub])

        let publisher = await stubbable.msgPublisher
        var received: Result<Data?, Err>?
        let cancellable = publisher.sink { value in
            received = value
        }

        let sendResult = await stubbable.send(Data(#"{"action":"ping","ts":999}"#.utf8))
        if case let .failure(error) = sendResult {
            #expect(Bool(false), "Expected stubbed send success, got \(error)")
        }

        try? await Task.sleep(nanoseconds: 1_000_000_000)
        let value = try #require(received)
        switch value {
        case let .success(data?):
            #expect(String(decoding: data, as: UTF8.self) == "stubbed")
        case .success(nil):
            #expect(Bool(false), "Expected stubbed data payload")
        case let .failure(err):
            #expect(Bool(false), "Expected success, got \(err)")
        }

        #expect(baseClient.sentPayloads.isEmpty, "Underlying client should not be called for stubbed messages")
        cancellable.cancel()
    }

    @Test func sendFallsThroughWhenNoStub() async {
        let baseClient = MockPublishedWSClient()
        let stubbable = PublishedStubbableWSClient(client: baseClient, logger: TestLogger())

        let result = await stubbable.send(Data("live".utf8))
        if case let .failure(error) = result {
            #expect(Bool(false), "Expected success, got \(error)")
        }

        #expect(baseClient.sentPayloads.count == 1)
        #expect(String(decoding: baseClient.sentPayloads[0], as: UTF8.self) == "live")
    }

    @Test func removeAllStubsDisablesStubbedResponses() async {
        let baseClient = MockPublishedWSClient()
        let stubbable = PublishedStubbableWSClient(client: baseClient, logger: TestLogger())

        let outgoing = PublishedStubbableWSClient.Stub.OutgoingMsg(
            outgoingMsgData: Data(#"{"a":1}"#.utf8),
            ignoringKeys: [],
            ignoringDeep: true
        )!
        let stub = PublishedStubbableWSClient.Stub(outgoingMsg: outgoing, incomingMsgData: Data("stubbed".utf8))!
        await stubbable.setStubs([stub])
        await stubbable.removeAllStubs()

        let result = await stubbable.send(Data(#"{"a":1}"#.utf8))
        switch result {
        case .success:
            #expect(baseClient.sentPayloads.count == 1)
        case let .failure(error):
            #expect(Bool(false), "Unexpected failure \(error)")
        }
    }
}

final class MockPublishedWSClient: IPublishedWSClient, @unchecked Sendable {
    @Published private var status: ConnectionStatus = .initial
    private let subject = PassthroughSubject<Result<Data?, Err>, Never>()

    private(set) var sentPayloads: [Data] = []

    func configure(with config: Config) async -> Result<Void, Err> { .success(()) }
    func connect() async -> Result<Void, Err> { .success(()) }
    func reconnect() async {}
    func disconnect() async {}

    func send(_ message: String) async -> Result<Void, Err> {
        sentPayloads.append(Data(message.utf8))
        return .success(())
    }

    func send(_ data: Data) async -> Result<Void, Err> {
        sentPayloads.append(data)
        return .success(())
    }

    var msgPublisher: AnyPublisher<Result<Data?, Err>, Never> {
        get async { subject.eraseToAnyPublisher() }
    }

    var connectionPublisher: Published<ConnectionStatus>.Publisher {
        get async { $status }
    }
}
