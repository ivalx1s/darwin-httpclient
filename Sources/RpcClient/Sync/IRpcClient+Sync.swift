import Foundation

public protocol IRpcClientSync {
    func get(
        path: String,
        headers: [HeaderKey: HeaderValue],
        queryParams: [ParamKey: ParamValue]
    ) -> Result<ApiResponse, ApiError>

    func post(
        path: String,
        headers: [HeaderKey: HeaderValue],
        queryParams: [ParamKey: ParamValue],
        bodyData: Data
    ) -> Result<ApiResponse, ApiError>

    func put(
        path: String,
        headers: [HeaderKey: HeaderValue],
        queryParams: [ParamKey: ParamValue],
        bodyData: Data
    ) -> Result<ApiResponse, ApiError>
}