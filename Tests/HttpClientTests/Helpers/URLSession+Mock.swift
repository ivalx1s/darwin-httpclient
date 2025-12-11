import Foundation

extension URLSession {
    static func mockedWithProtocol(_ proto: URLProtocol.Type) -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [proto]
        return URLSession(configuration: config)
    }
}
