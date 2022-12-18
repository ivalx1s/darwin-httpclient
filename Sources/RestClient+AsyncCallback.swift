import Foundation

extension RestClient {
    public func get(
            path: String,
            headers: [HeaderKey: HeaderValue] = [:],
            queryParams: [ParamKey: ParamValue] = [:],
            onSuccess: @escaping (ApiResponse) -> Void,
            onFail: @escaping (ApiError) -> Void
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

    public func post(
            path: String,
            headers: [HeaderKey: HeaderValue] = [:],
            queryParams: [ParamKey: ParamValue] = [:],
            bodyData: Data,
            onSuccess: @escaping (ApiResponse) -> Void,
            onFail: @escaping (ApiError) -> Void
    ) {
        request(type: .post, path: path,headers: headers, queryParams: queryParams, bodyData: bodyData, onSuccess: onSuccess, onFail: onFail)
    }

    func upload(
            path: String,
            headers: [HeaderKey: HeaderValue] = [:],
            body: Data,
            then handler: @escaping (Result<Data, ApiError>) -> Void
    ) {
        guard let url = buildRequestUrl(path: path, queryParams: [:]) else {
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
                completionHandler: { data, response, error in
                    if let response = response as? HTTPURLResponse {
                        print("response: \(response.statusCode)")
                    }
                    if let data = data {
                        print(String(data: data, encoding: .utf8) ?? "")
                    }
                    if let error = error {
                        print(error.localizedDescription)
                    }
                }
        )
        task.resume()
    }

    private func request(
            type: ApiRequestType,
            path: String,
            headers: [HeaderKey: HeaderValue] = [:],
            queryParams: [ParamKey: ParamValue] = [:],
            bodyData: Data? = nil,
            onSuccess: @escaping (ApiResponse) -> Void,
            onFail: @escaping (ApiError) -> Void
    ) {
        guard let url = buildRequestUrl(path: path, queryParams: queryParams) else {
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

        let request = buildRequest(url: url, type: type, headers: headers, bodyData: bodyData)

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
                                params: queryParams
                        )
                )
                return
            }

            onSuccess(ApiResponse(data: data, headers: response.allHeaderFields, code: response.statusCode))
        }

        task.resume()
    }
}