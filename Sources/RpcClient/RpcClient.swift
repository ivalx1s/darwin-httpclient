import Foundation
import Combine
import os.log

public actor RpcClient: IRpcClient {
    let session: URLSession

    public init(session: URLSession) {
        self.session = session
    }

    public init(
            sessionConfig: URLSessionConfiguration = ApiSessionConfigBuilder.buildConfig(
                    timeoutForResponse: 20,
                    timeoutResourceInterval: 120
            )
    ) {
        self.session = URLSession(configuration: sessionConfig)
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
