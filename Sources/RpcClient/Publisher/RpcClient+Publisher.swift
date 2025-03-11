import Foundation
import Combine

extension RpcClient {
    nonisolated public func perform(
            endpoint: ApiEndpoint,
            headers: [HeaderKey: HeaderValue],
            queryParams: [ParamKey: ParamValue],
            bodyData: Data?
    ) -> AnyPublisher<ApiResponse, ApiError> {
        switch endpoint.type {
        case .get:
            return get(path: endpoint.path, headers: headers, queryParams: queryParams)
        case .post:
            return post(path: endpoint.path, headers: headers, queryParams: queryParams, bodyData: bodyData)
        case .put:
            return put(path: endpoint.path, headers: headers, queryParams: queryParams, bodyData: bodyData)
        case .delete:
            return delete(path: endpoint.path, headers: headers, queryParams: queryParams, bodyData: bodyData)
        case .head:
            return head(path: endpoint.path, headers: headers, queryParams: queryParams)
        case .patch:
            return patch(path: endpoint.path, headers: headers, queryParams: queryParams, bodyData: bodyData)
        }
    }

    public nonisolated func get(
            path: String,
            headers: [HeaderKey: HeaderValue],
            queryParams: [ParamKey: ParamValue]
    ) -> AnyPublisher<ApiResponse, ApiError> {
        request(type: .get, path: path, headers: headers, queryParams: queryParams)
    }

    public nonisolated func post(
            path: String,
            headers: [HeaderKey: HeaderValue],
            queryParams: [ParamKey: ParamValue],
            bodyData: Data?
    ) -> AnyPublisher<ApiResponse, ApiError> {
        request(type: .post, path: path, headers: headers, queryParams: queryParams, bodyData: bodyData)
    }

    public nonisolated func put(
            path: String,
            headers: [HeaderKey: HeaderValue],
            queryParams: [ParamKey: ParamValue],
            bodyData: Data?
    ) -> AnyPublisher<ApiResponse, ApiError> {
        request(type: .put, path: path, headers: headers, queryParams: queryParams, bodyData: bodyData)
    }

    public nonisolated func delete(
            path: String,
            headers: [HeaderKey: HeaderValue],
            queryParams: [ParamKey: ParamValue],
            bodyData: Data?
    ) -> AnyPublisher<ApiResponse, ApiError> {
        request(type: .delete, path: path, headers: headers, queryParams: queryParams, bodyData: bodyData)
    }

    public nonisolated func head(
            path: String,
            headers: [HeaderKey: HeaderValue],
            queryParams: [ParamKey: ParamValue]
    ) -> AnyPublisher<ApiResponse, ApiError> {
        request(type: .delete, path: path, headers: headers, queryParams: queryParams)
    }

    public nonisolated func patch(
        path: String,
        headers: [HeaderKey: HeaderValue],
        queryParams: [ParamKey: ParamValue],
        bodyData: Data?
    ) -> AnyPublisher<ApiResponse, ApiError> {
        request(type: .patch,
                path: path,
                headers: headers,
                queryParams: queryParams)
    }

    private nonisolated func request(
            type: ApiRequestType,
            path: String,
            headers: [String: String],
            queryParams: [String: String],
            bodyData: Data? = nil
    ) -> AnyPublisher<ApiResponse, ApiError> {
        guard let url = Self.buildRequestUrl(path: path, queryParams: queryParams) else {
            return Fail(
                    error: ApiError(
                            sender: self,
                            url: path,
                            responseCode: 0,
                            message: "Unable to build url",
                            requestType: type,
                            headers: headers,
                            params: queryParams
                    )
            )
                    .eraseToAnyPublisher()
        }

        let request = Self.buildRpcRequest(url: url, type: type, headers: headers, bodyData: bodyData)

        let cURL = Self.create_cURL(requestType: type, path: url, headers: headers, bodyData: bodyData)
        log("\("🟡 beginning   \(type) \(path)")\n\(cURL)", category: .api)

        return session.dataTaskPublisher(for: request)
                .tryMap { data, response in
                    guard let response = response as? HTTPURLResponse else {
                        throw ApiError(
                            sender: self,
                            url: url.absoluteString,
                            responseCode: 0,
                            message: "no response: \(self.stringifyData(data: data))",
                            data: data,
                            requestType: type,
                            headers: headers,
                            params: queryParams
                        )
                    }

                    if response.statusCode < 200 || response.statusCode >= 300 {
                        throw ApiError(
                            sender: self,
                            url: url.absoluteString,
                            responseCode: response.statusCode,
                            message: "bad response: \(self.stringifyData(data: data))",
                            data: data,
                            requestType: type,
                            headers: headers,
                            params: queryParams,
                            responseHeaders: response.allHeaderFields.asResponseHeaders
                        )
                    } else if response.statusCode == 204 {
                        let apiResponse =  ApiResponse(data: nil, headers: response.allHeaderFields.asResponseHeaders, code: response.statusCode)
                        log("🟢 successful   \(type) \(path) \nresponse data: nil \nheaders: \(apiResponse.headers.payloads)\n", category: .api)
                        return apiResponse
                    }

                    let apiResponse = ApiResponse(data: data, headers: response.allHeaderFields.asResponseHeaders, code: response.statusCode)
                    log("🟢 successful   \(type) \(path) \nresponse data: \(data.utf8 ?? "") \nheaders: \(apiResponse.headers.payloads)\n", category: .api)

                    return apiResponse
                }
                .mapError { error in
                    // handle specific errors

                    if let error = error as? ApiError {
                        log("🔴 fail \(type) \(path) \nerror: \(error.toString())", category: .api)
                        return error
                    } else {
                        log("🔴 fail \(type) \(path) \nerror: \(error.localizedDescription)", category: .api)
                        return ApiError(
                            sender: self,
                            url: url.absoluteString,
                            responseCode: 0,
                            message: "Unknown error occurred \(error.localizedDescription)",
                            requestType: type,
                            headers: headers,
                            params: queryParams
                        )
                    }
                }
                .eraseToAnyPublisher()
    }

}
