import Foundation

// swiftlint:disable function_parameter_count
public actor RpcAsyncClientStubbable {
    private let logger: any HttpClientLogging
    private let client: IRpcAsyncClient
    private var rules: [ApiEndpoint: ApiResponse] = [:]

    public init(
        client: IRpcAsyncClient,
        logger: any HttpClientLogging = DefaultLogger.shared
    ) {
        self.client = client
        self.logger = logger
    }
}

extension RpcAsyncClientStubbable: IRpcAsyncClient {
    public func get(
        url: URL,
        headers: Headers,
        fileID: String,
        functionName: String,
        lineNumber: Int
    ) async -> Result<ApiResponse, ApiError> {
        let endpoint = ApiEndpoint(path: url.description, type: .get)
        switch rules[endpoint] {
            case let .some(stub):
                self.logResponse(endpoint: endpoint, response: stub)
                return .success(stub)
            case .none:
                return await self.client.get(
                    url: url,
                    headers: headers,
                    fileID: fileID,
                    functionName: functionName,
                    lineNumber: lineNumber
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
        let endpoint = ApiEndpoint(path: url.description, type: .get)
        switch rules[endpoint] {
            case let .some(stub):
                self.logResponse(endpoint: endpoint, response: stub)
                return .success(stub)
            case .none:
                return await self.client.get(
                    url: url,
                    headers: headers,
                    retrys: retrys,
                    fileID: fileID,
                    functionName: functionName,
                    lineNumber: lineNumber
                )
        }
    }

    public func performAsync(
        endpoint: ApiEndpoint,
        headers: Headers,
        queryParams: QueryParams,
        bodyData: Data?,
        fileID: String,
        functionName: String,
        lineNumber: Int
    ) async -> Result<ApiResponse, ApiError> {
        switch rules[endpoint] {
            case let .some(stub):
                self.logResponse(endpoint: endpoint, response: stub)
                return .success(stub)
            case .none:
                return await self.performAsync(
                    endpoint: endpoint,
                    headers: headers,
                    queryParams: queryParams,
                    bodyData: bodyData,
                    retrys: (count: 0, delay: { 1.0 }),
                    fileID: fileID,
                    functionName: functionName,
                    lineNumber: lineNumber
                )
        }
    }

    public func performAsync(
        endpoint: HttpClient.ApiEndpoint,
        headers: HttpClient.Headers,
        queryParams: HttpClient.QueryParams,
        bodyData: Data?,
        retrys: (count: UInt, delay: @Sendable () -> TimeInterval),
        fileID: String,
        functionName: String,
        lineNumber: Int
    ) async -> Result<HttpClient.ApiResponse, HttpClient.ApiError> {
        switch rules[endpoint] {
            case let .some(stub):
                self.logResponse(endpoint: endpoint, response: stub)
                return .success(stub)
            case .none:
                return await self.client.performAsync(
                    endpoint: endpoint,
                    headers: headers,
                    queryParams: queryParams,
                    bodyData: bodyData,
                    retrys: retrys,
                    fileID: fileID,
                    functionName: functionName,
                    lineNumber: lineNumber
                )
        }
    }
}

extension RpcAsyncClientStubbable {
    private func logResponse(endpoint: ApiEndpoint, response: ApiResponse) {
        logger.log("🔵 response stubbed for: \(endpoint.type) \(endpoint.path) \nresponse code: \(response.code) \nresponse data: \(response.data?.utf8 ?? "") \nheaders: \(response.headers.payloads)\n")
    }
}
extension RpcAsyncClientStubbable: IRpcAsyncClientStubbable {
    public func upsert(rule: HttpClient.ApiEndpoint, stub: HttpClient.ApiResponse) async {
        self.rules[rule] = stub
    }

    public func upsert(rules: [HttpClient.ApiEndpoint: HttpClient.ApiResponse]) async {
        self.rules.merge(rules, uniquingKeysWith: { _, right in right })
    }

    public func remove(rule: HttpClient.ApiEndpoint) async {
        self.rules.removeValue(forKey: rule)
    }

    public func removeAllRules() async {
        self.rules.removeAll()
    }
}

// swiftlint:enable function_parameter_count
