import Foundation
import Combine

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public protocol IPublishedStubbableWSClient: IPublishedWSClient {
    typealias Stub = PublishedStubbableWSClient.Stub

    func removeAllStubs() async
    func setStubs(_ stubs: [Stub]) async
}

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public actor PublishedStubbableWSClient {
    private let internalMsgSub: PassthroughSubject<Result<Data?, WSClientError>, Never> = .init()
    private var internalMsgPub: AnyPublisher<Result<Data?, WSClientError>, Never> {
        internalMsgSub.eraseToAnyPublisher()
    }
    private let client: IPublishedWSClient
    private var rules: [Stub] = []

    public init(
        client: IPublishedWSClient
    ) {
        self.client = client
    }
}

extension PublishedStubbableWSClient: IPublishedWSClient {
    public func configure(with config: Config) async -> Result<Void, Err> {
        await self.client.configure(with: config)
    }

    public func connect() async -> Result<Void, Err> {
        await self.client.connect()
    }

    public func reconnect() async {
        await self.client.reconnect()
    }

    public func disconnect() async {
        await self.client.disconnect()
    }

    public func send(_ message: String) async -> Result<Void, Err> {
        switch await self.checkStubForOutgoingMessage(message) {
            case .none:
                await self.client.send(message)
            case let .some(stub):
                .success(riseStub(stub.incomingMsgData))
        }
    }

    public func send(_ data: Data) async -> Result<Void, Err>{
        switch await self.checkStubForOutgoingMessage(data) {
            case .none:
                await self.client.send(data)
            case let .some(stub):
                .success(riseStub(stub.incomingMsgData))
        }
    }

    public var msgPublisher: AnyPublisher<Result<Data?, Err>, Never> {
        get async {
            Publishers
                .Merge(
                    await self.client.msgPublisher,
                    internalMsgPub
                )
                .eraseToAnyPublisher()
        }
    }

    public var connectionPublisher: Published<ConnectionStatus>.Publisher {
        get async {
            await self.client.connectionPublisher
        }
    }
}

extension PublishedStubbableWSClient: IPublishedStubbableWSClient {
    public func setStubs(_ stubs: [Stub]) async {
        self.rules = stubs
    }

    public func removeAllStubs() async {
        self.rules.removeAll()
    }

    private func checkStubForOutgoingMessage(_ msg: String) async -> Stub? {
        await checkStubForOutgoingMessage(Data(msg.utf8))
    }

    private func checkStubForOutgoingMessage(_ msg: Data) async -> Stub? {
        rules
            .first { rule in
                guard let newMsgKey = try? msg.stableNormalizedJSONString(
                    ignoringKeys: rule.outgoingMsg.ignoringKeys,
                    deep: rule.outgoingMsg.ignoringDeep
                )
                else { return false }
                return rule.key == newMsgKey
            }
    }

    private func riseStub(_ data: Data) {
        log(">>>🔵 incoming msg stubbed: \(String(data: data, encoding: .utf8) ?? "NaS")")
        internalMsgSub.send(.success(data))
    }
}
