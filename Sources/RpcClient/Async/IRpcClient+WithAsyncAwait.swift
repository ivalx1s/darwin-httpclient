import Foundation

extension Result: Sendable where Success: Sendable, Failure: Sendable {}

public protocol IRpcAsyncClient: Sendable {
    func get(
        url: URL,
        headers: Headers,
        fileID: String,
        functionName: String,
        lineNumber: Int
    ) async -> Result<ApiResponse, ApiError>

    func performAsync(
        endpoint: ApiEndpoint,
        headers: Headers,
        queryParams: QueryParams,
        bodyData: Data?,
        fileID: String,
        functionName: String,
        lineNumber: Int
    ) async -> Result<ApiResponse, ApiError>

    func performAsync(
        endpoint: ApiEndpoint,
        headers: Headers,
        queryParams: QueryParams,
        bodyData: Data?,
        retrys: (count: UInt, delay: @Sendable ()->(TimeInterval)),
        fileID: String,
        functionName: String,
        lineNumber: Int
    ) async -> Result<ApiResponse, ApiError>
}
