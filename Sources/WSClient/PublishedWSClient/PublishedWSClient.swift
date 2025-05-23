import Foundation
import Combine

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public protocol IPublishedWSClient: Sendable {
    typealias ConnectionStatus = PublishedWSClient.UrlSessionDelegate.Status
    typealias Config = PublishedWSClient.Config
    typealias Err = WSClientError

    func configure(with config: Config) async -> Result<Void, Err>
    func connect() async -> Result<Void, Err>
    func reconnect() async
    func disconnect() async
    func send(_ message: String) async -> Result<Void, Err>
    func send(_ data: Data) async -> Result<Void, Err>
    var msgPublisher: AnyPublisher<Result<Data?, Err>, Never> { get async }
    var connectionPublisher: Published<ConnectionStatus>.Publisher { get async }
}

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public actor PublishedWSClient: IPublishedWSClient, IRequestBuilder {
    private var internalKeepConnected: Toggle = .off

    private var keepConnected: Toggle { get { internalKeepConnected } }
    private var webSocketTask: URLSessionWebSocketTask?
    private var keepAliveSubscription: AnyCancellable?
    private let delegate: UrlSessionDelegate
    private var receiveMessagesTask : Task<Void, any Error>?

    nonisolated
    private var instanceId: String { ObjectIdentifier(self).debugDescription }
    private var currentDateStr: String { Date.now.formatted(date: .omitted, time: .standard) }
    private var config: Config?
    
    internal let logger: any HttpClientLogging

    public init(logger: any HttpClientLogging, delegate: UrlSessionDelegate? = nil) {
        self.logger = logger
        if let delegate {
            self.delegate = delegate
        } else {
            self.delegate = UrlSessionDelegate(logger: logger)
        }
        logger.log(">>>> ws init: \(self.instanceId)")
    }

    deinit {
        logger.log(">>>> ws deinit: \(self.instanceId)")
    }

    private var msgSubj = PassthroughSubject<Result<Data?, Err>, Never>()
    public var msgPublisher: AnyPublisher<Result<Data?, Err>, Never> {
        get async { msgSubj.eraseToAnyPublisher() }
    }

    public var connectionPublisher: Published<ConnectionStatus>.Publisher {
        get async { delegate.$status }
    }

    @discardableResult
    public func configure(with config: Config) async -> Result<Void, Err>{
        self.config = config

        guard self.keepConnected == .off else {
            print(">>> ws \(instanceId) configure in connection")
            return .failure(Err.failedToBuildRequest(forUrlPath: config.urlPath))
        }

        guard let url = Self.buildRequestUrl(path: config.urlPath, queryParams: [:]) else {
            return .failure(Err.failedToBuildRequest(forUrlPath: config.urlPath))
        }

        let request = Self.buildWSRequest(url: url, headers: await config.headers())
        let urlSession = URLSession(configuration: config.sessionConfig, delegate: delegate, delegateQueue: nil)

        let webSocketTask = urlSession.webSocketTask(with: request)
        logger.log(">>> ws \(instanceId) configure wsSocketTaskId \(ObjectIdentifier(webSocketTask))")
        self.webSocketTask = webSocketTask

        self.setupKeepAlivePipeline(with: config.pingInterval)

        return .success(())
    }

    @discardableResult
    public func connect() async -> Result<Void, Err> {
        logger.log(">>> ws \(instanceId) \(currentDateStr) connect start \(keepConnected)")

        guard let webSocketTask = webSocketTask
        else { return .failure(.notConfigured) }

        logger.log(">>> ws \(instanceId) connect wsSocketTaskId \(ObjectIdentifier(webSocketTask))")

        webSocketTask.resume()
        self.internalKeepConnected = .on
        self.receiveMessagesTask = Task { await receiveMessages() }

        return .success(())
    }

    public func reconnect() async { await self.reconnect(with: 0) }
    private func reconnect(with interval: UInt32) async {
        logger.log(">>> ws \(instanceId) \(currentDateStr) reconnect start \(keepConnected)")

        guard self.keepConnected == .on else {
            logger.log(">>> ws \(instanceId) \(currentDateStr) reconnect not connected \(keepConnected)")
            return
        }

        await self.disconnect()

        sleep(interval)

        guard let config = self.config else { return }
        guard case .success = await self.configure(with: config) else { return }

        await self.connect()
    }

    public func disconnect() async {
        logger.log(">>> ws \(instanceId) disconnect start \(keepConnected)")
        self.internalKeepConnected = .off
        self.receiveMessagesTask?.cancel()

        guard let webSocketTask else { return }
        logger.log(">>> ws \(instanceId) disconnect wsSocketTaskId \(ObjectIdentifier(webSocketTask))")
        webSocketTask.cancel(with: .normalClosure, reason: nil)
    }

    public func send(_ message: String) async -> Result<Void, Err> {
        let msg = URLSessionWebSocketTask.Message.string(message)
        return await send(msg: msg)
    }

    public func send(_ data: Data) async -> Result<Void, Err> {
        let msg = URLSessionWebSocketTask.Message.data(data)
        return await send(msg: msg)
    }

    private func setupKeepAlivePipeline(with pingDelay: TimeInterval) {
        self.keepAliveSubscription = Timer.publish(every: pingDelay, on: .main, in: .common).autoconnect()
            .sink { [weak self] _ in
                guard let self,
                      case .on = await self.keepConnected,
                      self.delegate.status == .connected
                else { return }

                await self.sendPing()
            }
    }

    private func sendPing() {
        webSocketTask?.sendPing { [weak self] err in
            guard let self else { return }

            switch err {
                case .none:
                logger.log(">>> ws \(self.instanceId)  ping")
                case let .some(err):
                logger.log(">>> ws \(self.instanceId) ping err: \(err)")
            }
        }
    }

    private func receiveMessages() async {
        while self.keepConnected == .on {
            let result = await self.awaitNextMessage()
            self.msgSubj.send(result)
            switch result {
                case let .success(data):
                logger.log(">>> ws \(self.instanceId) msg received: \(data?.utf8 ?? "")")
                case let .failure(err):
                logger.log(">>> ws \(self.instanceId) transport error: \(err)")
                    Task.detached { [weak self] in
                        guard let self else { return }
                        await self.reconnect(with: self.config?.reconnectInterval ?? 0)
                    }
                    return
            }
        }
    }

    private func awaitNextMessage() async -> Result<Data?, WSClientError> {
        do {
            guard let webSocketTask
            else { return .failure(.notConfigured) }
            logger.log(">>> ws awaitNextMessage wsSocketTaskId: \(ObjectIdentifier(webSocketTask))")
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
            return .failure(.transportError(cause: error, connectionStatus: delegate.status))
        }
    }

    private func send(msg: URLSessionWebSocketTask.Message) async -> Result<Void, WSClientError> {
        do {
            guard let webSocketTask else {
                return .failure(.failedToSend_NotConnected(msg: msg))
            }

            logger.log(">>> ws \(instanceId) message sent to wsSocketTaskId \(ObjectIdentifier(webSocketTask)): \(msg)")

            try await webSocketTask.send(msg)
            return .success(())
        } catch {
            logger.log(">>> ws \(instanceId) message send failed: \(msg) \(error)")
            return .failure(.failedToSend(msg: msg, cause: error))
        }
    }
}
