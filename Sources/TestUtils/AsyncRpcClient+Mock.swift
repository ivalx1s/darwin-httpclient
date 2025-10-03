import Foundation

public actor RpcClientWithAsyncAwaitMock {
    private static let defaultError: ApiError = .init(sender: "Mock Client", endpoint: .init(path: "default-error", type: .get))

    public init() {}

    public var getCalls: [(url: URL, headers: Headers, retrys: RetryParams?)] = []
    public var performCalls: [Call] = []

    private var getResult: Result<ApiResponse, ApiError> = .failure(defaultError)
    private var performResult: Result<ApiResponse, ApiError> = .failure(defaultError)

    public func setPerfomResult(_ result: Result<ApiResponse, ApiError>) {
        performResult = result
    }

    public func setGetResult(_ result: Result<ApiResponse, ApiError>) {
        getResult = result
    }
}

extension RpcClientWithAsyncAwaitMock: IRpcAsyncClient {
    public func get(url: URL, fileID: String, functionName: String, lineNumber: Int) async -> Result<ApiResponse, ApiError> {
        getCalls.append((url: url, headers: [:], retrys: .none))
        return getResult
    }

    public func get(url: URL, headers: Headers, fileID: String, functionName: String, lineNumber: Int) async -> Result<ApiResponse, ApiError> {
        getCalls.append((url: url, headers: headers, retrys: .none))
        return getResult
    }

    public func get(url: URL, headers: Headers, retrys: RequestRetrys, fileID: String, functionName: String, lineNumber: Int) async -> Result<ApiResponse, ApiError> {
        getCalls.append((url: url, headers: headers, retrys: .init(count: retrys.count, delay: retrys.delay)))
        return getResult
    }

    public func get(url: URL, headers: Headers, retrys: RetryParams, fileID: String, functionName: String, lineNumber: Int) async -> Result<ApiResponse, ApiError> {
        getCalls.append((url: url, headers: headers, retrys: retrys))
        return getResult
    }

    public func get(url: URL) async -> Result<ApiResponse, ApiError> {
        getCalls.append((url: url, headers: [:], retrys: .none))
        return getResult
    }

    public func get(url: URL, headers: Headers) async -> Result<ApiResponse, ApiError> {
        getCalls.append((url: url, headers: headers, retrys: .none))
        return getResult
    }

    public func performAsync(endpoint: ApiEndpoint, headers: Headers, queryParams: QueryParams, bodyData: Data?) async -> Result<ApiResponse, ApiError> {
        performCalls.append(.init(endpoint: endpoint, headers: headers, queryParams: queryParams, bodyData: bodyData, retrys: .none))
        return performResult
    }

    public func performAsync(endpoint: ApiEndpoint, headers: Headers, queryParams: QueryParams, bodyData: Data?, fileID: String, functionName: String, lineNumber: Int) async -> Result<ApiResponse, ApiError> {
        performCalls.append(.init(endpoint: endpoint, headers: headers, queryParams: queryParams, bodyData: bodyData, retrys: .none))
        return performResult
    }

    public func performAsync(endpoint: ApiEndpoint, headers: Headers, queryParams: QueryParams, bodyData: Data?, retrys: RequestRetrys, fileID: String, functionName: String, lineNumber: Int) async -> Result<ApiResponse, ApiError> {
        performCalls.append(.init(endpoint: endpoint, headers: headers, queryParams: queryParams, bodyData: bodyData, retrys: .init(count: retrys.count, delay: retrys.delay)))
        return performResult
    }

    public func performAsync(endpoint: ApiEndpoint, headers: Headers, queryParams: QueryParams, bodyData: Data?, retrys: RetryParams, fileID: String, functionName: String, lineNumber: Int) async -> Result<ApiResponse, ApiError> {
        performCalls.append(.init(endpoint: endpoint, headers: headers, queryParams: queryParams, bodyData: bodyData, retrys: retrys))
        return performResult
    }
}

extension RpcClientWithAsyncAwaitMock {
    public struct Call: Sendable {
        let endpoint: ApiEndpoint
        let headers: Headers
        let queryParams: QueryParams
        let bodyData: Data?
        let retrys: RetryParams?
    }
}
