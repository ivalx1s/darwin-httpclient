import Foundation

extension PublishedWSClient.UrlSessionDelegate {
    public enum Status: Equatable, CustomDebugStringConvertible {
        case initial
        case connected
        case disconnected(closeCode: URLSessionWebSocketTask.CloseCode)

        public var isConnected: Bool {
            switch self {
                case .connected: return true
                case .initial, .disconnected: return false
            }
        }

        public var debugDescription: String {
            switch self {
                case .initial: return "initial"
                case .connected: return "connected"
                case let .disconnected(closeCode): return "disconnected(closeCode: \(closeCode))"
            }
        }
    }
}

extension PublishedWSClient {
    public class UrlSessionDelegate: NSObject, URLSessionWebSocketDelegate {
        @Published public var status: Status = .initial

        public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
            log(">>> ws didOpenWithProtocol \(`protocol` ?? "")")
            self.status = .connected
        }

        public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
            log(">>> ws didCloseWith \(closeCode) \(reason?.utf8 ?? "")")
            self.status = .disconnected(closeCode: closeCode)
        }
    }
}
