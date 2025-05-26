import Foundation

extension RpcClient: IRpcAsyncClient {
    public func performAsync(
        endpoint: ApiEndpoint,
        headers: Headers,
        queryParams: QueryParams,
        bodyData: Data?
    ) async -> Result<ApiResponse, ApiError> {
        await request(type: endpoint.type, path: endpoint.path, headers: headers, queryParams: queryParams, bodyData: bodyData)
    }

    public func performAsync(
            endpoint: ApiEndpoint,
            headers: Headers,
            queryParams: QueryParams,
            bodyData: Data?,
            fileID: String = #fileID,
            functionName: String = #function,
            lineNumber: Int = #line
    ) async -> Result<ApiResponse, ApiError> {
        await request(type: endpoint.type, path: endpoint.path, headers: headers, queryParams: queryParams, bodyData: bodyData, fileID: fileID, functionName: functionName, lineNumber: lineNumber)
    }

    public func performAsync(
        endpoint: ApiEndpoint,
        headers: Headers,
        queryParams: QueryParams,
        bodyData: Data?,
        retrys: RequestRetrys,
        fileID: String = #fileID,
        functionName: String = #function,
        lineNumber: Int = #line
    ) async -> Result<ApiResponse, ApiError> {
        switch await request(type: endpoint.type, path: endpoint.path, headers: headers, queryParams: queryParams, bodyData: bodyData, fileID: fileID, functionName: functionName, lineNumber: lineNumber) {
            case let .success(response): return .success(response)
            case let .failure(err):
                guard retrys.count > 0 else { return .failure(err) }
                try? await Task.sleep(nanoseconds: UInt64(1_000_000_000 * retrys.delay()))
                return await performAsync(
                    endpoint: endpoint,
                    headers: headers,
                    queryParams: queryParams,
                    bodyData: bodyData,
                    retrys: (count: max(0, retrys.count - 1), delay: retrys.delay),
                    fileID: fileID,
                    functionName: functionName,
                    lineNumber: lineNumber
                ) 
        }
    }

    public func get(
            path: String,
            headers: Headers,
            queryParams: QueryParams,
            fileID: String = #fileID,
            functionName: String = #function,
            lineNumber: Int = #line
    ) async -> Result<ApiResponse, ApiError> {
        await request(type: .get, path: path, headers: headers, queryParams: queryParams, fileID: fileID, functionName: functionName, lineNumber: lineNumber)
    }

    public func post(
            path: String,
            headers: Headers,
            queryParams: QueryParams,
            bodyData: Data?,
            fileID: String = #fileID,
            functionName: String = #function,
            lineNumber: Int = #line
    ) async -> Result<ApiResponse, ApiError> {
        await request(type: .post, path: path, headers: headers, queryParams: queryParams, bodyData: bodyData, fileID: fileID, functionName: functionName, lineNumber: lineNumber)
    }

    public func put(
            path: String,
            headers: Headers,
            queryParams: QueryParams,
            bodyData: Data?,
            fileID: String = #fileID,
            functionName: String = #function,
            lineNumber: Int = #line
    ) async -> Result<ApiResponse, ApiError> {
        await request(type: .put, path: path, headers: headers, queryParams: queryParams, bodyData: bodyData, fileID: fileID, functionName: functionName, lineNumber: lineNumber)
    }

    public func delete(
            path: String,
            headers: Headers,
            queryParams: QueryParams,
            bodyData: Data?,
            fileID: String = #fileID,
            functionName: String = #function,
            lineNumber: Int = #line
    ) async -> Result<ApiResponse, ApiError> {
        await request(type: .delete, path: path, headers: headers, queryParams: queryParams, bodyData: bodyData, fileID: fileID, functionName: functionName, lineNumber: lineNumber)
    }

    public func head(
            path: String,
            headers: Headers,
            queryParams: QueryParams,
            fileID: String = #fileID,
            functionName: String = #function,
            lineNumber: Int = #line
    ) async -> Result<ApiResponse, ApiError> {
        await request(type: .delete, path: path, headers: headers, queryParams: queryParams, fileID: fileID, functionName: functionName, lineNumber: lineNumber)
    }

    public func patch(
        path: String,
        headers: Headers,
        queryParams: QueryParams,
        fileID: String = #fileID,
        functionName: String = #function,
        lineNumber: Int = #line
    ) async -> Result<ApiResponse, ApiError> {
        await request(type: .patch,
                      path: path,
                      headers: headers,
                      queryParams: queryParams,
                      fileID: fileID,
                      functionName: functionName,
                      lineNumber: lineNumber)
    }

    public func get(
        url: URL,
        fileID: String = #fileID,
        functionName: String = #function,
        lineNumber: Int = #line
    ) async -> Result<ApiResponse, ApiError> {
        await get(url: url, headers: [:], fileID: fileID, functionName: functionName, lineNumber: lineNumber)
    }

    public func get(
        url: URL
    ) async -> Result<ApiResponse, ApiError> {
        await get(url: url, headers: [:], fileID: #fileID, functionName: #function, lineNumber: #line)
    }

    public func get(
        url: URL,
        headers: Headers
    ) async -> Result<ApiResponse, ApiError> {
        await get(url: url, headers: headers, fileID: #fileID, functionName: #function, lineNumber: #line)
    }


    public func get(
        url: URL,
        headers: Headers,
        fileID: String = #fileID,
        functionName: String = #function,
        lineNumber: Int = #line
    ) async -> Result<ApiResponse, ApiError> {
        let request = Self.buildRpcRequest(url: url, type: .get, headers: headers, bodyData: nil)
        let cURL = Self.create_cURL(requestType: .get, path: url, headers: headers, bodyData: nil)
        logger.log("\("🟡 beginning \(ApiRequestType.get) \(url.description)")\n\(cURL)")

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
                    headers: headers,
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
                    headers: headers,
                    params: [:],
                    responseHeaders: response.allHeaderFields.asResponseHeaders
                )
            } else if response.statusCode == 204 {
                let apiResponse =  ApiResponse(data: nil, headers: response.allHeaderFields.asResponseHeaders, code: response.statusCode)
                logger.log("🟢 successful   \(ApiRequestType.get) \(url.description) \nresponse data: nil \nheaders: \(apiResponse.headers.payloads)\n")
                return .success(apiResponse)
            }

            let apiResponse = ApiResponse(data: data, headers: response.allHeaderFields.asResponseHeaders, code: response.statusCode)
            logger.log("🟢 successful   \(ApiRequestType.get) \(url.description) \nresponse data: \(data.utf8 ?? "") \nheaders: \(apiResponse.headers.payloads)\n")
            return .success(apiResponse)
        } catch let error as ApiError {
            logger.log("🔴 fail \(ApiRequestType.get) \(url.description) \nerror: \(error.localizedDescription)")
            return .failure(error)
        } catch {
            logger.log("🔴 fail \(ApiRequestType.get) \(url.description) \nerror: \(error.localizedDescription)")
            return .failure(
                ApiError(sender: self, endpoint: .init(path: url.description, type: .get))
            )
        }
    }

    public func get(
        url: URL,
        headers: Headers,
        retrys: RequestRetrys,
        fileID: String,
        functionName: String,
        lineNumber: Int
    ) async -> Result<ApiResponse, ApiError> {
        switch await get(url: url, headers: headers, fileID: fileID, functionName: functionName, lineNumber: lineNumber) {
            case let .success(response): return .success(response)
            case let .failure(err):
                guard retrys.count > 0 else { return .failure(err) }
                try? await Task.sleep(nanoseconds: UInt64(1_000_000_000 * retrys.delay()))
                return await get(
                    url: url,
                    headers: headers,
                    retrys: (count: max(0, retrys.count - 1), delay: retrys.delay),
                    fileID: fileID,
                    functionName: functionName,
                    lineNumber: lineNumber
                )
        }
    }

    private func request(
            type: ApiRequestType,
            path: String,
            headers: [String: String],
            queryParams: [String: String],
            bodyData: Data? = nil,
            fileID: String = #fileID,
            functionName: String = #function,
            lineNumber: Int = #line
    ) async -> Result<ApiResponse, ApiError> {
        do {
            guard let url = Self.buildRequestUrl(path: path, queryParams: queryParams) else {
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

            let request = Self.buildRpcRequest(url: url, type: type, headers: headers, bodyData: bodyData)

            let cURL = Self.create_cURL(requestType: type, path: url, headers: headers, bodyData: bodyData)
            logger.log("\("🟡 beginning   \(type) \(path)")\n\(cURL)")

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
                    params: queryParams,
                    responseHeaders: response.allHeaderFields.asResponseHeaders
                )
            } else if response.statusCode == 204 {
                let apiResponse =  ApiResponse(data: nil, headers: response.allHeaderFields.asResponseHeaders, code: response.statusCode)
                logger.log("🟢 successful   \(type) \(path) \nresponse data: nil \nheaders: \(apiResponse.headers.payloads)\n")
                return .success(apiResponse)
            }

            let apiResponse = ApiResponse(data: data, headers: response.allHeaderFields.asResponseHeaders, code: response.statusCode)
            logger.log("🟢 successful   \(type) \(path) \nresponse data: \(data.utf8 ?? "") \nheaders: \(apiResponse.headers.payloads)\n")
            return .success(apiResponse)

        } catch let error as ApiError {
            logger.log("🔴 fail \(type) \(path) \nerror: \(error.responseCode): \(error.localizedDescription)\nresponse headers: \(error.responseHeaders)")
            return .failure(error)
        } catch {
            logger.log("🔴 fail \(type) \(path) \nerror: \(error.localizedDescription)")
            return .failure(
                ApiError(sender: self, endpoint: .init(path: path, type: type))
            )
        }
    }
}
