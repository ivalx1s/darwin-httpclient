import Foundation

extension RpcClient: IRpcCompletionClient {
    nonisolated public func get(
            path: String,
            headers: [HeaderKey: HeaderValue] = [:],
            queryParams: [ParamKey: ParamValue] = [:],
            onSuccess: @Sendable @escaping (ApiResponse) -> Void,
            onFail: @Sendable @escaping (ApiError) -> Void
    ) {
        request(
                type: .get,
                path: path,
                headers: headers,
                queryParams: queryParams,
                onSuccess: onSuccess,
                onFail: onFail
        )
    }

    public nonisolated func post(
            path: String,
            headers: [HeaderKey: HeaderValue] = [:],
            queryParams: [ParamKey: ParamValue] = [:],
            bodyData: Data,
            onSuccess: @Sendable @escaping (ApiResponse) -> Void,
            onFail: @Sendable @escaping (ApiError) -> Void
    ) {
        request(type: .post, path: path,headers: headers, queryParams: queryParams, bodyData: bodyData, onSuccess: onSuccess, onFail: onFail)
    }

    nonisolated func upload(
            path: String,
            headers: [HeaderKey: HeaderValue] = [:],
            body: Data,
            then handler: @escaping (Result<Data, ApiError>) -> Void
    ) {
        guard let url = Self.buildRequestUrl(path: path, queryParams: [:]) else {
            handler(.failure(
                    ApiError(sender: self, url: path, responseCode: 0, requestType: .post, headers: headers, params: [:]))
            )
            return
        }
        var request = URLRequest(url: url)
        headers.forEach {
            request.setValue($0.value, forHTTPHeaderField: $0.key)
        }
        request.httpMethod = ApiRequestType.post.rawValue
        request.httpBody = body

        let task = session.uploadTask(
                with: request,
                from: body,
                completionHandler: { [weak self] data, response, error in
                    if let response = response as? HTTPURLResponse {
                        self?.logger.log("response: \(response.statusCode)")
                    }
                    if let data = data {
                        self?.logger.log(String(data: data, encoding: .utf8) ?? "")
                    }
                    if let error = error {
                        self?.logger.log(error.localizedDescription)
                    }
                }
        )
        task.resume()
    }

    private nonisolated func request(
            type: ApiRequestType,
            path: String,
            headers: [HeaderKey: HeaderValue] = [:],
            queryParams: [ParamKey: ParamValue] = [:],
            bodyData: Data? = nil,
            onSuccess: @Sendable @escaping (ApiResponse) -> Void,
            onFail: @Sendable @escaping (ApiError) -> Void
    ) {
        guard let url = Self.buildRequestUrl(path: path, queryParams: queryParams) else {
            onFail(
                ApiError(
                        sender: self,
                        url: path,
                        responseCode: 0,
                        message: "response: nil",
                        requestType: type,
                        headers: headers,
                        params: queryParams
                )
            )
            return
        }

        let request = Self.buildRpcRequest(url: url, type: type, headers: headers, bodyData: bodyData)

        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                onFail(
                    ApiError(
                            sender: self,
                            url: path,
                            responseCode: 0,
                            message: "\(self) error",
                            error: error,
                            requestType: type,
                            headers: headers,
                            params: queryParams
                    )
                )
            }

            guard let response = response as? HTTPURLResponse else {
                onFail(
                    ApiError(
                            sender: self,
                            url: path,
                            responseCode: 0,
                            message: "response: nil",
                            requestType: type,
                            headers: headers,
                            params: queryParams
                    )
                )
                return
            }

            guard response.statusCode == 200 else {
                onFail(
                    ApiError(
                            sender: self,
                            url: path,
                            responseCode: response.statusCode,
                            message: "incorrect request",
                            requestType: type,
                            headers: headers,
                            params: queryParams
                    )
                )
                return
            }

            guard let data = data else {
                onFail(
                    ApiError(
                            sender: self,
                            url: path,
                            responseCode: response.statusCode,
                            message: "data: nil",
                            requestType: type,
                            headers: headers,
                            params: queryParams,
                            responseHeaders: response.allHeaderFields.asResponseHeaders
                    )
                )
                return
            }

            onSuccess(ApiResponse(data: data, headers: response.allHeaderFields.asResponseHeaders, code: response.statusCode))
        }

        task.resume()
    }
}
