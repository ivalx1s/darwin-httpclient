import Foundation

public protocol IRpcClientWithCallback {
    func get(
        path: String,
        headers: [HeaderKey: HeaderValue],
        queryParams: [ParamKey: ParamValue],
        onSuccess: @escaping (ApiResponse) -> Void,
        onFail: @escaping (ApiError) -> Void
    )

    func post(
        path: String,
        headers: [HeaderKey: HeaderValue],
        queryParams: [ParamKey: ParamValue],
        bodyData: Data,
        onSuccess: @escaping (ApiResponse) -> Void,
        onFail: @escaping (ApiError) -> Void
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
