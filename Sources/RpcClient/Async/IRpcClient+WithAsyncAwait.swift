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

    func get(
        url: URL,
        headers: Headers,
        retrys: RequestRetrys,
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
        retrys: RequestRetrys,
        fileID: String,
        functionName: String,
        lineNumber: Int
    ) async -> Result<ApiResponse, ApiError>
}
