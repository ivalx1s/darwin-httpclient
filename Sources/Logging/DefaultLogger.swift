public struct DefaultLogger: HttpClientLogging, Sendable {
    public static let shared = DefaultLogger()
    private init() {}
    public func log(_ message: String) {
        print(message)
    }
}
