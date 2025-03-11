import Foundation

public protocol IRpcClientWithCallback {
    func get(
        path: String,
        headers: [HeaderKey: HeaderValue],
        queryParams: [ParamKey: ParamValue],
        onSuccess: @Sendable @escaping (ApiResponse) -> Void,
        onFail: @Sendable @escaping (ApiError) -> Void
    )

    func post(
        path: String,
        headers: [HeaderKey: HeaderValue],
        queryParams: [ParamKey: ParamValue],
        bodyData: Data,
        onSuccess: @Sendable @escaping (ApiResponse) -> Void,
        onFail: @Sendable @escaping (ApiError) -> Void
    )

    func delete(
        path: String,
        headers: [HeaderKey: HeaderValue],
        queryParams: [ParamKey: ParamValue],
        bodyData: Data?
    ) -> Result<ApiResponse, ApiError>

    func head(
        path: String,
        headers: [HeaderKey: HeaderValue],
        queryParams: [ParamKey: ParamValue]
    ) -> Result<ApiResponse, ApiError>
}
