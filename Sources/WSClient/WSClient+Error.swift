import Foundation

public enum WSClientError: Error {
    case disconnected
    case failedToPing(cause: Error)
    case failedToBuildRequest(forUrlPath: String)
    case coddingError(cause: Error)
    case transportError(cause: Error? = .none, connectionStatus: PublishedWSClient.UrlSessionDelegate.Status)
    case failedToReceiveMsg_UnsupportedMsgType(type: URLSessionWebSocketTask.Message)
    case failedToConnect_noHeaders
    case failedToSend(msg: URLSessionWebSocketTask.Message, cause: Error)
    case failedToSend_NotConnected(msg: URLSessionWebSocketTask.Message)
}