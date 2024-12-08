import Foundation

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public enum WSClientError: Error {
    case notConfigured
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
