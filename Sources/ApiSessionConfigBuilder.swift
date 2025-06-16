import Foundation

public class ApiSessionConfigBuilder {
    public static func buildConfig(
            timeoutForResponse: Double,
            timeoutResourceInterval: Double,
            disableCookieStorage: Bool = false
    ) -> URLSessionConfiguration {
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = timeoutForResponse
        sessionConfig.timeoutIntervalForResource = timeoutResourceInterval
        if disableCookieStorage {
            sessionConfig.httpCookieStorage = .none
        }
        return sessionConfig
    }
}
