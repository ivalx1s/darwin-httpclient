import Foundation

public protocol IWSClient {
    func connect(to urlPath : String, with headers: Headers) async -> Result<AsyncStream<Result<Data, WSClientError>>, WSClientError>
    func disconnect() async
    func send(_ message: String) async -> Result<Void, WSClientError>
    func send(_ data: Data) async -> Result<Void, WSClientError>
}

public actor WSClient: IWSClient, IRequestBuilder {
    private var webSocketTask: URLSessionWebSocketTask?
    private let urlSession: URLSession

    public init(urlSession: URLSession) {
        self.urlSession = urlSession
    }

    public init(
        sessionConfig: URLSessionConfiguration = ApiSessionConfigBuilder.buildConfig(
            timeoutForResponse: 20,
            timeoutResourceInterval: 120
        )
    ) {
        self.urlSession = URLSession(configuration: sessionConfig)
    }

    public func connect(to urlPath : String, with headers: Headers) async -> Result<AsyncStream<Result<Data, WSClientError>>, WSClientError> {
        guard let url = buildRequestUrl(path: urlPath, queryParams: [:]) else {
            return .failure(WSClientError.failedToBuildRequest(forUrlPath: urlPath))
        }
        let request = buildWSRequest(url: url, headers: headers)
        webSocketTask = urlSession.webSocketTask(with: request)
        webSocketTask?.resume()

        return .success(streamMessages())
    }

    public func disconnect() async {
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

    private func streamMessages() -> AsyncStream<Result<Data, WSClientError>>  {
        AsyncStream { continuation in
            Task {
                while let webSocketTask {
                    guard webSocketTask.closeCode == .invalid else {
                        log(">>>> websocket: connection closed \(webSocketTask.closeCode)")
                        continuation.finish()
                        return
                    }

                    continuation.yield(await awaitNextMessage())
                }
            }
        }
    }

    private func awaitNextMessage() async -> Result<Data, WSClientError> {
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
                return .failure(.failedToReceiveMsg_UnsupportedMsgType(type: msg))
            }
        } catch {
           await disconnect()
            return .failure(.disconnected)
        }
    }

    private func send(msg: URLSessionWebSocketTask.Message) async -> Result<Void, WSClientError> {
        do {
            guard let webSocketTask else {
                return .failure(.failedToSend_ConnectionLost(msg: msg))
            }
            try await webSocketTask.send(msg)
            return .success(())
        } catch {
            return .failure(.failedToSend(msg: msg, cause: error))
        }
    }
}