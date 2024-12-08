import Foundation

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
extension PublishedWSClient {
    public struct Config {
        let pingInterval: TimeInterval
        let reconnectInterval: UInt32
        let sessionConfig: URLSessionConfiguration
        let urlPath: String
        let headers: () async -> Headers

        public init(
            pingInterval: UInt32 = 10,
            reconnectInterval: UInt32 = 1,
            sessionConfig: URLSessionConfiguration? = nil,
            urlPath: String,
            headers: @escaping () async -> Headers
        ) {
            self.pingInterval = Double(pingInterval)
            self.reconnectInterval = reconnectInterval
            self.sessionConfig = sessionConfig ?? ApiSessionConfigBuilder.buildConfig(
                timeoutForResponse: 120,
                timeoutResourceInterval: 604800
            )
            self.urlPath = urlPath
            self.headers = headers
        }
    }
}

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
extension PublishedWSClient.Config: Equatable {
    public static func ==(lhs : PublishedWSClient.Config, rhs : PublishedWSClient.Config) -> Bool {
        lhs.pingInterval == rhs.pingInterval
            && lhs.reconnectInterval == rhs.reconnectInterval
            && lhs.urlPath == rhs.urlPath
            && ObjectIdentifier(lhs.headers as AnyObject) == ObjectIdentifier(rhs.headers as AnyObject)
    }
}
