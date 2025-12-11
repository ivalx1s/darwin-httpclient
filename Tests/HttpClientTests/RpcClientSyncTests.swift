import Foundation
import Testing
@testable import HttpClient

@Suite(.serialized) struct RpcClientSyncTests {
    @Test func syncGetSuccess() throws {
        let urlString = "https://example.com/sync"
        MockURLProtocol.setHandler(for: urlString) { request in
            #expect(request.url?.absoluteString == urlString)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["X-Test": "1"])!
            return (response, nil) // status code is enough for coverage
        }
        defer { MockURLProtocol.setHandler(for: urlString, handler: nil) }

        let client = RpcClient(session: .mockedWithProtocol(MockURLProtocol.self), logger: TestLogger())
        let result: Result<ApiResponse, ApiError> = (client as IRpcSyncClient).get(path: urlString, headers: [:], queryParams: [:])

        switch result {
        case let .success(apiResponse):
            #expect(apiResponse.code == 200)
            #expect(apiResponse.data?.isEmpty == true)
            #expect(apiResponse.headers.payloads["X-Test"] as? String == "1")
        case let .failure(error):
            #expect(Bool(false), "Expected success, got \(error)")
        }
    }

    @Test func syncGetFailure() throws {
        let urlString = "https://example.com/sync-fail"
        MockURLProtocol.setHandler(for: urlString) { request in
            #expect(request.url?.absoluteString == urlString)
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: "HTTP/1.1", headerFields: nil)!
            return (response, Data("err".utf8))
        }
        defer { MockURLProtocol.setHandler(for: urlString, handler: nil) }

        let client = RpcClient(session: .mockedWithProtocol(MockURLProtocol.self), logger: TestLogger())
        let result: Result<ApiResponse, ApiError> = (client as IRpcSyncClient).get(path: urlString, headers: [:], queryParams: [:])

        switch result {
        case .success:
            #expect(Bool(false), "Expected failure")
        case let .failure(error):
            #expect(error.responseCode == 500)
            #expect(error.rawData?.utf8 == "err")
        }
    }
}
