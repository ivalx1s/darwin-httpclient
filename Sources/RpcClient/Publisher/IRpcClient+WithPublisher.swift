import Combine
import Foundation

public protocol IRpcPublisherClient: Sendable {
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
