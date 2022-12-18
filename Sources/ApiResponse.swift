import Foundation

public struct ApiResponse {
    public let data: Data?
    public let headers: ResponseHeaders
    public let code: ResponseCode

    public func headerValue(forKey: String) -> String? {
        headers.first { "\($0.key)".lowercased() == forKey.lowercased()}?.value as? String
    }
}
