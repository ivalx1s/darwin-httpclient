import Foundation

public enum WSClientError: Error {
    case disconnected
    case failedToPing(cause: Error)
    case failedToBuildRequest(forUrlPath: String)
    case failedToReceiveMsg(cause: Error? = .none)
    case failedToReceiveMsg_UnsupportedMsgType(type: URLSessionWebSocketTask.Message)
    case failedToConnect_noHeaders
    case failedToSend(msg: URLSessionWebSocketTask.Message, cause: Error)
    case failedToSend_ConnectionLost(msg: URLSessionWebSocketTask.Message)
}