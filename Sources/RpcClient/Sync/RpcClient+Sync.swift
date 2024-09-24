import Foundation

extension RpcClient {
    public func get(
            path: String,
            headers: [HeaderKey: HeaderValue] = [:],
            queryParams: [ParamKey: ParamValue] = [:]
    ) -> Result<ApiResponse, ApiError> {
        request(
                type: .get,
                path: path,
                headers: headers,
                queryParams: queryParams
        )
    }

    public func post(
            path: String,
            headers: [HeaderKey: HeaderValue] = [:],
            queryParams: [ParamKey: ParamValue] = [:],
            bodyData: Data
    ) -> Result<ApiResponse, ApiError> {
        request(
                type: .post,
                path: path,
                headers: headers,
                queryParams: queryParams,
                bodyData: bodyData
        )
    }

    public func put(
            path: String,
            headers: [HeaderKey: HeaderValue] = [:],
            queryParams: [ParamKey: ParamValue] = [:],
            bodyData: Data
    ) -> Result<ApiResponse, ApiError> {
        request(
                type: .put,
                path: path,
                headers: headers,
                queryParams: queryParams,
                bodyData: bodyData
        )
    }

    public func delete(
            path: String,
            headers: [HeaderKey: HeaderValue] = [:],
            queryParams: [ParamKey: ParamValue] = [:],
            bodyData: Data?
    ) -> Result<ApiResponse, ApiError> {
        request(
                type: .delete,
                path: path,
                headers: headers,
                queryParams: queryParams,
                bodyData: bodyData
        )
    }

    public func head(
            path: String,
            headers: [HeaderKey: HeaderValue] = [:],
            queryParams: [ParamKey: ParamValue] = [:]
    ) -> Result<ApiResponse, ApiError> {
        request(
                type: .head,
                path: path,
                headers: headers,
                queryParams: queryParams
        )
    }

    public func patch(
        path: String,
        headers: [HeaderKey: HeaderValue] = [:],
        queryParams: [ParamKey: ParamValue] = [:]
    ) -> Result<ApiResponse, ApiError> {
        request(
            type: .patch,
            path: path,
            headers: headers,
            queryParams: queryParams
        )
    }

    private func request(
            type: ApiRequestType,
            path: String,
            headers: [HeaderKey: HeaderValue] = [:],
            queryParams: [ParamKey: ParamValue] = [:],
            bodyData: Data? = nil
    ) -> Result<ApiResponse, ApiError> {
        guard let url = buildRequestUrl(path: path, queryParams: queryParams) else {
            return .failure(ApiError(
                    sender: self,
                    url: path,
                    responseCode: 0,
                    message: "incorrect url",
                    requestType: type,
                    headers: headers,
                    params: queryParams
            ))
        }

        var request = URLRequest(url: url)

        headers.forEach {
            request.setValue($0.value, forHTTPHeaderField: $0.key)
        }

        request.httpMethod = type.rawValue

        switch type {
        case .post, .put, .delete:
            request.httpBody = bodyData
        default:
            break
        }

        var result: Result<ApiResponse, ApiError>!

        let semaphore = DispatchSemaphore(value: 0)

        let cURL = create_cURL(requestType: type, path: url, headers: headers, bodyData: bodyData)
        log("\("🟡 beginning   \(type) \(path)")\n\(cURL)", category: .api)

        let task = session.dataTask(with: request) {[weak self] data, response, error in
            if let _ = error {
                result = .failure(
                        ApiError(
                                sender: self as Any,
                                url: path,
                                responseCode: 0,
                                message: "error occurred: \(self?.stringifyData(data: data) ?? "") ",
                                error: error,
                                requestType: type,
                                headers: headers,
								params: queryParams
                        )
                )
                semaphore.signal()
            }

            guard let response = response as? HTTPURLResponse else {
                result = .failure(
                        ApiError(
                                sender: self as Any,
                                url: path,
                                responseCode: 0,
                                message: "no response: \(self?.stringifyData(data: data) ?? "")",
                                requestType: type,
                                headers: headers,
                                params: queryParams
                        )
                )
                semaphore.signal()
                return
            }

            if response.statusCode < 200 || response.statusCode >= 300 {
                result = .failure(
                        ApiError(
                                sender: self as Any,
                                url: path,
                                responseCode: response.statusCode,
                                message: "bad response: \(self?.stringifyData(data: data) ?? "")",
                                data: data,
                                requestType: type,
                                headers: headers,
                                params: queryParams,
                                responseHeaders: response.allHeaderFields.asResponseHeaders
                        )
                )
                semaphore.signal()
                return
            } else if response.statusCode == 204 {
                result = .success(ApiResponse(data: nil, headers: response.allHeaderFields.asResponseHeaders, code: response.statusCode))
                semaphore.signal()
                return
            }

            result = .success(ApiResponse(data: data, headers: response.allHeaderFields.asResponseHeaders, code: response.statusCode))
            semaphore.signal()
        }

        task.resume()

        _ = semaphore.wait(wallTimeout: .distantFuture)

        switch result {
        case .success(let response):
            log("🟢 successful   \(type) \(path) \nresponse data: \(response.data?.utf8 ?? "") \nheaders: \(response.headers)\n", category: .api)

        case .failure(let error):
            log("🔴 failed \(type) \(path) \nerror: \(error.toString())", category: .api)
        case .none:
            break
        }

        return result
    }

}
