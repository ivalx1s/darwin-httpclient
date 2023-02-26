import Foundation

public protocol IRpcClientWithAsyncAwait {
    func request(url: URL) async -> Result<ApiResponse, ApiError>

    func performAsync(
        endpoint: ApiEndpoint,
        headers: [HeaderKey: HeaderValue],
        queryParams: [ParamKey: ParamValue],
        bodyData: Data?
    ) async -> Result<ApiResponse, ApiError>
}