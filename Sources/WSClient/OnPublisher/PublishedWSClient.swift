import Foundation
import Combine

public protocol IPublishedWSClient {
    func connect(to urlPath : String, with headers: @escaping ()->Headers) -> Result<Void, WSClientError>
    func connect(to urlPath : String) -> Result<Void, WSClientError>
    func disconnect()
    func send(_ message: String) async -> Result<Void, WSClientError>
    func send(_ data: Data) async -> Result<Void, WSClientError>
    var msgPublisher: AnyPublisher<Result<Data?, WSClientError>, Never> { get }
}

public class PublishedWSClient: NSObject, IPublishedWSClient, IRequestBuilder {
    enum KeepConnected {
        case on(url: String, headers: ()->Headers)
        case off
    }
    private var webSocketTask: URLSessionWebSocketTask?
    @Published private var keepConnected: KeepConnected = .off
    private var keepAliveSubscription: AnyCancellable?
    private let pingDelay: UInt32

    public init(pingInterval: UInt32 = 10) {
        self.pingDelay = pingInterval
        super.init()
        self.keepAlivePipeline()
    }

    deinit {
        keepAliveSubscription?.cancel()
    }

    private var msgSubj = PassthroughSubject<Result<Data?, WSClientError>, Never>()
    public var msgPublisher: AnyPublisher<Result<Data?, WSClientError>, Never> { msgSubj.eraseToAnyPublisher() }

    public func connect(to urlPath : String) -> Result<Void, WSClientError> {
        connect(to: urlPath, with: {[:]})
    }

    public func connect(to urlPath : String, with headers: @escaping ()->Headers) -> Result<Void, WSClientError> {
        guard let url = buildRequestUrl(path: urlPath, queryParams: [:]) else {
            return .failure(WSClientError.failedToBuildRequest(forUrlPath: urlPath))
        }

        let request = buildWSRequest(url: url, headers: headers())
        let urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)

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
             _ = connect(to: url, with: headers)
         case .off: break
         }
    }

    public func disconnect() {
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
                    guard case .on = self.keepConnected else { return }
                    self.sendPing()
                }
            }
    }

    private func sendPing() {
        webSocketTask?.sendPing { [weak self] err in
            switch err {
            case .none:
                print(">>> ws ping")
            case let .some(err):
                print(">>> ws ping err: \(err)")
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
                    print(">>> websocket: connection closed \(webSocketTask.closeCode)")
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

extension PublishedWSClient: URLSessionWebSocketDelegate {
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print(">>> ws didOpenWithProtocol \(`protocol` ?? "")")
    }

    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print(">>> ws didCloseWith \(closeCode) \(reason?.utf8 ?? "")")
    }
}