import Foundation
import Combine

public protocol IPublishedWSClient {
    func connect(to urlPath : String, with headers: @escaping ()async->Headers) async -> Result<Void, WSClientError>
    func connect(to urlPath : String) async -> Result<Void, WSClientError>
    func reconnect() async
    func disconnect() async
    func send(_ message: String) async -> Result<Void, WSClientError>
    func send(_ data: Data) async -> Result<Void, WSClientError>
    var msgPublisher: AnyPublisher<Result<Data?, WSClientError>, Never> { get async }
}

extension PublishedWSClient {
    class UrlSessionDelegate: NSObject, URLSessionWebSocketDelegate {
        public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
            log(">>> ws didOpenWithProtocol \(`protocol` ?? "")")
        }

        public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
            log(">>> ws didCloseWith \(closeCode) \(reason?.utf8 ?? "")")
        }
    }
}

extension PublishedWSClient {
    enum KeepConnected {
        case on(url: String, headers: ()async->Headers)
        case off
    }
}

public actor PublishedWSClient: IPublishedWSClient, IRequestBuilder {
    private var webSocketTask: URLSessionWebSocketTask?
    @Published private var keepConnected: KeepConnected = .off
    private var keepAliveSubscription: AnyCancellable?
    private let pingDelay: UInt32
    private let sessionConfig: URLSessionConfiguration
    private let delegate = UrlSessionDelegate()

    public init(
        pingInterval: UInt32 = 10,
        sessionConfig: URLSessionConfiguration? = nil
    ) {
        self.pingDelay = pingInterval
        self.sessionConfig = sessionConfig ?? ApiSessionConfigBuilder.buildConfig(
            timeoutForResponse: 120,
            timeoutResourceInterval: 604800
        )
        Task { await self.keepAlivePipeline() }
    }

    deinit {
        keepAliveSubscription?.cancel()
    }

    private var msgSubj = PassthroughSubject<Result<Data?, WSClientError>, Never>()
    public var msgPublisher: AnyPublisher<Result<Data?, WSClientError>, Never> {
        get async { msgSubj.eraseToAnyPublisher() }
    }

    public func connect(to urlPath : String) async -> Result<Void, WSClientError> {
        await connect(to: urlPath, with: {[:]})
    }

    public func connect(to urlPath : String, with headers: @escaping ()async->Headers) async -> Result<Void, WSClientError> {
        guard let url = buildRequestUrl(path: urlPath, queryParams: [:]) else {
            return .failure(WSClientError.failedToBuildRequest(forUrlPath: urlPath))
        }

        let authHeaders = await headers()
        guard !authHeaders.isEmpty else {
            return .failure(.failedToConnect_noHeaders)
        }

        let request = buildWSRequest(url: url, headers: authHeaders)
        let urlSession = URLSession(configuration: sessionConfig, delegate: delegate, delegateQueue: nil)

        self.keepConnected = .on(url: urlPath, headers: headers)
        webSocketTask = urlSession.webSocketTask(with: request)
        webSocketTask?.resume()

        publishMessages()
        return .success(())
    }

    public func reconnect() async {
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

    private func keepAlivePipeline() {
        keepAliveSubscription = Timer.publish(every: Double(pingDelay), on: .main, in: .common).autoconnect()
            .sink { _ in
                Task { [weak self] in
                    guard let self else { return }
                    guard case .on = await self.keepConnected
                    else { return }
                    await self.sendPing()
                }
            }
    }

    private func sendPing() {
        webSocketTask?.sendPing { [weak self] err in
            switch err {
            case .none:
                log(">>> ws ping")
            case let .some(err):
                log(">>> ws ping err: \(err)")
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
                    log(">>> websocket: connection closed \(webSocketTask.closeCode)")
                    return
                }
                let result = await awaitNextMessage()
                msgSubj.send(result)
                switch result {
                case let .success(data):
                    log(">>> ws msg received: \(data?.utf8 ?? "")")
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
            log(">>> ws message sent: \(msg)")
            return .success(())
        } catch {
            log(">>> ws message send failed: \(msg) \(error)")
            return .failure(.failedToSend(msg: msg, cause: error))
        }
    }
}