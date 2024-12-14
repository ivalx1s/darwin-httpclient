import Foundation

extension Result: Sendable where Success: Sendable, Failure: Sendable {}

public protocol IRpcClientWithAsyncAwait: Actor {
    func get(
        url: URL,
        fileID: String,
        functionName: String,
        lineNumber: Int
    ) async -> Result<ApiResponse, ApiError>

    func get(
        url: URL,
        headers: Headers,
        fileID: String,
        functionName: String,
        lineNumber: Int
    ) async -> Result<ApiResponse, ApiError>

    func get(
        url: URL
    ) async -> Result<ApiResponse, ApiError>

    func get(
        url: URL,
        headers: Headers
    ) async -> Result<ApiResponse, ApiError>

    func performAsync(
        endpoint: ApiEndpoint,
        headers: Headers,
        queryParams: QueryParams,
        bodyData: Data?
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
}
