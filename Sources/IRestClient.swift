import Foundation
import Combine

public protocol IRestClient {
    func performAsync(
            endpoint: ApiEndpoint,
            headers: [HeaderKey: HeaderValue],
            queryParams: [ParamKey: ParamValue],
            bodyData: Data?
    ) async -> Result<ApiResponse, ApiError>

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

    func get(
            path: String,
            headers: [HeaderKey: HeaderValue],
            queryParams: [ParamKey: ParamValue]
    ) -> AnyPublisher<ApiResponse, ApiError>

    func post(
            path: String,
            headers: [HeaderKey: HeaderValue],
            queryParams: [ParamKey: ParamValue],
            bodyData: Data?
    ) -> AnyPublisher<ApiResponse, ApiError>

    func put(
            path: String,
            headers: [HeaderKey: HeaderValue],
            queryParams: [ParamKey: ParamValue],
            bodyData: Data?
    ) -> AnyPublisher<ApiResponse, ApiError>

    func delete(
            path: String,
            headers: [HeaderKey: HeaderValue],
            queryParams: [ParamKey: ParamValue],
            bodyData: Data?
    ) -> AnyPublisher<ApiResponse, ApiError>

    func head(
            path: String,
            headers: [HeaderKey: HeaderValue],
            queryParams: [ParamKey: ParamValue]
    ) -> AnyPublisher<ApiResponse, ApiError>

    func perform(
            endpoint: ApiEndpoint,
            headers: [HeaderKey: HeaderValue],
            queryParams: [ParamKey: ParamValue],
            bodyData: Data?
    ) -> AnyPublisher<ApiResponse, ApiError>
}
