
public extension ApiError {
    static func stub(
        endpoint: ApiEndpoint = ApiEndpoint(path: "", type: .get),
        code: Int
    ) -> Self {
        .init(
            sender: "Mock",
            endpoint: endpoint,
            responseCode: code
        )
    }
}
