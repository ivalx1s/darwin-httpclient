import Foundation
import Testing
@testable import HttpClient

@Suite(.serialized) struct RpcClientCallbackTests {
    @Test func callbackSuccess() async {
        let urlString = "https://example.com/callback"
        MockURLProtocol.setHandler(for: urlString) { request in
            #expect(request.url?.absoluteString == urlString)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)!
            return (response, Data("ok".utf8))
        }
        defer { MockURLProtocol.setHandler(for: urlString, handler: nil) }

        let client = RpcClient(session: .mockedWithProtocol(MockURLProtocol.self), logger: TestLogger())

        let result = await withCheckedContinuation { continuation in
            client.get(path: urlString, headers: [:], queryParams: [:]) { apiResponse in
                continuation.resume(returning: Result<ApiResponse, ApiError>.success(apiResponse))
            } onFail: { apiError in
                continuation.resume(returning: Result<ApiResponse, ApiError>.failure(apiError))
            }
        }

        switch result {
        case let .success(apiResponse):
            #expect(apiResponse.code == 200)
            #expect(apiResponse.data?.utf8 == "ok")
        case let .failure(error):
            #expect(Bool(false), "Expected success, got \(error)")
        }
    }

    @Test func callbackFailure() async {
        let urlString = "https://example.com/callback-fail"
        MockURLProtocol.setHandler(for: urlString) { request in
            #expect(request.url?.absoluteString == urlString)
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: "HTTP/1.1", headerFields: nil)!
            return (response, Data("err".utf8))
        }
        defer { MockURLProtocol.setHandler(for: urlString, handler: nil) }

        let client = RpcClient(session: .mockedWithProtocol(MockURLProtocol.self), logger: TestLogger())

        let result = await withCheckedContinuation { continuation in
            client.get(path: urlString, headers: [:], queryParams: [:]) { apiResponse in
                continuation.resume(returning: Result<ApiResponse, ApiError>.success(apiResponse))
            } onFail: { apiError in
                continuation.resume(returning: Result<ApiResponse, ApiError>.failure(apiError))
            }
        }

        switch result {
        case .success:
            #expect(Bool(false), "Expected failure")
        case let .failure(error):
            #expect(error.responseCode == 500)
        }
    }
}
