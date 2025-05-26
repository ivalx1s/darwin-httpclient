import Foundation
import Combine

public actor RpcClient {
    let session: URLSession
    internal nonisolated let logger: any HttpClientLogging

    public init(
        session: URLSession,
        logger: any HttpClientLogging = DefaultLogger.shared
    ) {
        self.session = session
        self.logger = logger
    }

    public init(
            sessionConfig: URLSessionConfiguration = ApiSessionConfigBuilder.buildConfig(
                    timeoutForResponse: 20,
                    timeoutResourceInterval: 120
            ),
            logger: any HttpClientLogging = DefaultLogger.shared
    ) {
        self.session = URLSession(configuration: sessionConfig)
        self.logger = logger
    }
}

extension RpcClient {
    nonisolated func stringifyData(data: Data?) -> String {
        let htmlPrefix = "<!doctype html>"
        guard let data = data else {
            return ""
        }

        guard let str = String(data: data, encoding: .utf8) else {
            return ""
        }

        return str.replacingOccurrences(of: htmlPrefix, with: "")
    }
}

extension RpcClient: IRequestBuilder {}
