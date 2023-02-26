import Foundation

extension RpcClient {

    public func performAsync(
            endpoint: ApiEndpoint,
            headers: Headers,
            queryParams: QueryParams,
            bodyData: Data?
    ) async -> Result<ApiResponse, ApiError> {
        switch endpoint.type {
        case .get:
            return await get(path: endpoint.path, headers: headers, queryParams: queryParams)
        case .post:
            return await post(path: endpoint.path, headers: headers, queryParams: queryParams, bodyData: bodyData)
        case .put:
            return await put(path: endpoint.path, headers: headers, queryParams: queryParams, bodyData: bodyData)
        case .delete:
            return await delete(path: endpoint.path, headers: headers, queryParams: queryParams, bodyData: bodyData)
        case .head:
            return await head(path: endpoint.path, headers: headers, queryParams: queryParams)
        }
    }

    public func get(
            path: String,
            headers: Headers,
            queryParams: QueryParams
    ) async -> Result<ApiResponse, ApiError> {
        await request(type: .get, path: path, headers: headers, queryParams: queryParams)
    }

    public func post(
            path: String,
            headers: Headers,
            queryParams: QueryParams,
            bodyData: Data?
    ) async -> Result<ApiResponse, ApiError> {
        await request(type: .post, path: path, headers: headers, queryParams: queryParams, bodyData: bodyData)
    }

    public func put(
            path: String,
            headers: Headers,
            queryParams: QueryParams,
            bodyData: Data?
    ) async -> Result<ApiResponse, ApiError> {
        await request(type: .put, path: path, headers: headers, queryParams: queryParams, bodyData: bodyData)
    }

    public func delete(
            path: String,
            headers: Headers,
            queryParams: QueryParams,
            bodyData: Data?
    ) async -> Result<ApiResponse, ApiError> {
        await request(type: .delete, path: path, headers: headers, queryParams: queryParams, bodyData: bodyData)
    }

    public func head(
            path: String,
            headers: Headers,
            queryParams: QueryParams
    ) async -> Result<ApiResponse, ApiError> {
        await request(type: .delete, path: path, headers: headers, queryParams: queryParams)
    }

    public func request(url: URL) async -> Result<ApiResponse, ApiError> {
        let request = buildRpcRequest(url: url, type: .get, headers: [:], bodyData: nil)
        let cURL = create_cURL(requestType: .get, path: url, headers: [:], bodyData: nil)
        log("\("🟡 beginning \(ApiRequestType.get) \(url.description)")\n\(cURL)", category: .api)

        do {
            let (data, response) = try await session.data(for: request)

            guard let response = response as? HTTPURLResponse else {
                throw ApiError(
                        sender: self,
                        url: url.absoluteString,
                        responseCode: 0,
                        message: "no response: \(self.stringifyData(data: data))",
                        data: data,
                        requestType: .get,
                        headers: [:],
                        params: [:]
                )
            }

            if response.statusCode < 200 || response.statusCode >= 300 {
                throw ApiError(
                        sender: self,
                        url: url.absoluteString,
                        responseCode: response.statusCode,
                        message: "bad response: \(self.stringifyData(data: data))",
                        data: data,
                        requestType: .get,
                        headers: [:],
                        params: [:]
                )
            } else if response.statusCode == 204 {
                let apiResponse =  ApiResponse(data: nil, headers: response.allHeaderFields, code: response.statusCode)
                log("🟢 successful   \(ApiRequestType.get) \(url.description) \nresponse data: nil \nheaders: \(apiResponse.headers)\n", category: .api)
                return .success(apiResponse)
            }

            let apiResponse = ApiResponse(data: data, headers: response.allHeaderFields, code: response.statusCode)
            log("🟢 successful   \(ApiRequestType.get) \(url.description) \nresponse data: \(data.utf8 ?? "") \nheaders: \(apiResponse.headers)\n", category: .api)
            return .success(apiResponse)
        } catch let error as ApiError {
            log("🔴 fail \(ApiRequestType.get) \(url.description) \nerror: \(error.localizedDescription)", category: .api)
            return .failure(error)
        } catch {
            log("🔴 fail \(ApiRequestType.get) \(url.description) \nerror: \(error.localizedDescription)", category: .api)
            return .failure(
                    ApiError(sender: self, endpoint: .init(path: url.description, type: .get))
            )
        }
    }

    private func request(
            type: ApiRequestType,
            path: String,
            headers: [String: String],
            queryParams: [String: String],
            bodyData: Data? = nil
    ) async -> Result<ApiResponse, ApiError> {
        do {
            guard let url = buildRequestUrl(path: path, queryParams: queryParams) else {
                throw ApiError(
                        sender: self,
                        url: path,
                        responseCode: 0,
                        message: "Unable to build url",
                        requestType: type,
                        headers: headers,
                        params: queryParams
                )
            }

            let request = buildRpcRequest(url: url, type: type, headers: headers, bodyData: bodyData)

            let cURL = create_cURL(requestType: type, path: url, headers: headers, bodyData: bodyData)
            log("\("🟡 beginning   \(type) \(path)")\n\(cURL)", category: .api)

            let (data, response) = try await session.data(for: request)

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
                        params: queryParams
                )
            } else if response.statusCode == 204 {
                let apiResponse =  ApiResponse(data: nil, headers: response.allHeaderFields, code: response.statusCode)
                log("🟢 successful   \(type) \(path) \nresponse data: nil \nheaders: \(apiResponse.headers)\n", category: .api)
                return .success(apiResponse)
            }

            let apiResponse = ApiResponse(data: data, headers: response.allHeaderFields, code: response.statusCode)
            log("🟢 successful   \(type) \(path) \nresponse data: \(data.utf8 ?? "") \nheaders: \(apiResponse.headers)\n", category: .api)
            return .success(apiResponse)

        } catch let error as ApiError {
            log("🔴 fail \(type) \(path) \nerror: \(error.responseCode): \(error.localizedDescription)", category: .api)
            return .failure(error)
        } catch {
            log("🔴 fail \(type) \(path) \nerror: \(error.localizedDescription)", category: .api)
            return .failure(
                    ApiError(sender: self, endpoint: .init(path: path, type: type))
            )
        }
    }
}
