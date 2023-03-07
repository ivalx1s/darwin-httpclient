import Foundation
import Combine

public protocol IPublishedWSClient {
    func connect(to urlPath : String, with headers: @escaping ()->Headers) async -> Result<Void, WSClientError>
    func disconnect() async
    func send(_ message: String) async -> Result<Void, WSClientError>
    func send(_ data: Data) async -> Result<Void, WSClientError>
    var msgPublisher: AnyPublisher<Result<Data?, WSClientError>, Never> { get async }
}

public actor PublishedWSClient: IPublishedWSClient, IRequestBuilder {
    enum KeepConnected {
        case on(url: String, headers: ()->Headers)
        case off
    }
    private var webSocketTask: URLSessionWebSocketTask?
    private let sessionConfig: URLSessionConfiguration
    @Published private var keepConnected: KeepConnected = .off
    private var keepAliveSubscription: AnyCancellable?
    private let pingDelay: UInt32 = 5

    public init(
        sessionConfig: URLSessionConfiguration = ApiSessionConfigBuilder.buildConfig(
            timeoutForResponse: 20,
            timeoutResourceInterval: 20
        )
    ) {
        self.sessionConfig = sessionConfig
        Task { await self.keepAlivePipeline() }
    }

    deinit {
        keepAliveSubscription?.cancel()
    }

    private var msgSubj = PassthroughSubject<Result<Data?, WSClientError>, Never>()
    public var msgPublisher: AnyPublisher<Result<Data?, WSClientError>, Never> { msgSubj.eraseToAnyPublisher() }

    public func connect(to urlPath : String, with headers: @escaping ()->Headers) async -> Result<Void, WSClientError> {
        guard let url = buildRequestUrl(path: urlPath, queryParams: [:]) else {
            return .failure(WSClientError.failedToBuildRequest(forUrlPath: urlPath))
        }

        let request = buildWSRequest(url: url, headers: headers())
        let urlSession = URLSession(configuration: sessionConfig)

        self.keepConnected = .on(url: urlPath, headers: headers)
        webSocketTask = urlSession.webSocketTask(with: request)
        webSocketTask?.resume()

        publishMessages()
        return .success(())
    }

    private func reconnect() async {
         switch keepConnected {
         case let .on(url, headers):
             webSocketTask?.cancel()
             _ = await connect(to: url, with: headers)
         case .off: break
         }
    }

    public func disconnect() async {
        keepConnected = .off
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
    }

    public func send(_ message: String) async -> Result<Void, WSClientError> {
        let msg = URLSessionWebSocketTask.Message.string(message)
        return await send(msg: msg)
    }

    public func send(_ data: Data) async -> Result<Void, WSClientError> {
        let msg = URLSessionWebSocketTask.Message.data(data)
        return await send(msg: msg)
    }

    private func keepAlivePipeline() async {
        keepAliveSubscription = Timer.publish(every: Double(pingDelay), on: .main, in: .common).autoconnect()
            .sink { _ in
                Task { [weak self] in
                    guard let self else { return }
                    guard case .on = await self.keepConnected else { return }
                    await self.sendPing()
                }
            }
    }

    private func sendPing() {
        webSocketTask?.sendPing { [weak self] err in
            switch err {
            case .none:
                print(">>>> ws ping")
            case let .some(err):
                print(">>>> ws ping err: \(err)")
                Task { [weak self] in
                    await self?.reconnect()
                }
            }
        }
    }

    private func publishMessages() {
        Task {
            while let webSocketTask {
                guard webSocketTask.closeCode == .invalid else {
                    print(">>>> websocket: connection closed \(webSocketTask.closeCode)")
                    return
                }
                let result = await awaitNextMessage()
                msgSubj.send(result)
                switch result {
                case let .success(data):
                    print(">>> ws msg received: \(data?.utf8 ?? "")")
                case .failure:
                    sleep(pingDelay)
                    await reconnect()
                }
            }
        }
    }

    private func awaitNextMessage() async -> Result<Data?, WSClientError> {
        do {
            guard let webSocketTask else {
                return .failure(.failedToReceiveMsg_ConnectionLost)
            }
            let msg = try await webSocketTask.receive()
            switch msg {
            case let .string(str):
                return .success(str.data(using: .utf8) ?? Data())
            case let .data(data):
                return .success(data)
            @unknown default:
                return .success(nil)
            }
        } catch {
            return .failure(.failedToReceiveMsg(cause: error))
        }
    }

    private func send(msg: URLSessionWebSocketTask.Message) async -> Result<Void, WSClientError> {
        do {
            guard let webSocketTask else {
                return .failure(.failedToSend_ConnectionLost(msg: msg))
            }
            try await webSocketTask.send(msg)
            print(">>> ws message sent: \(msg)")
            return .success(())
        } catch {
            print(">>> ws message send failed: \(msg) \(error)")
            return .failure(.failedToSend(msg: msg, cause: error))
        }
    }
}