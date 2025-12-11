import Foundation
import Testing
@testable import HttpClient

@Suite(.serialized) struct RpcClientAsyncTests {
    @Test func getReturnsSuccess() async throws {
        let url = try #require(URL(string: "https://example.com/success"))
        var attempts = 0

        MockURLProtocol.setHandler(for: url.absoluteString) { request in
            attempts += 1
            #expect(request.url == url)
            let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "text/plain"]
            )!
            return (response, Data("ok".utf8))
        }
        defer { MockURLProtocol.setHandler(for: url.absoluteString, handler: nil) }

        let client = RpcClient(session: .mockedWithProtocol(MockURLProtocol.self), logger: TestLogger())
        let result = await client.get(url: url)

        switch result {
        case let .success(apiResponse):
            #expect(apiResponse.code == 200)
            #expect(apiResponse.data?.utf8 == "ok")
            #expect(attempts == 1, "MockURLProtocol should intercept exactly once")
        case let .failure(error):
            #expect(Bool(false), "Expected success, got \(error)")
        }
    }

    @Test func getRetriesThenSucceeds() async throws {
        let url = try #require(URL(string: "https://example.com/retry"))

        var attempts = 0
        MockURLProtocol.setHandler(for: url.absoluteString) { _ in
            attempts += 1
            if attempts == 1 {
                let response = HTTPURLResponse(
                    url: url,
                    statusCode: 500,
                    httpVersion: "HTTP/1.1",
                    headerFields: [:]
                )!
                return (response, Data("err".utf8))
            } else {
                let response = HTTPURLResponse(
                    url: url,
                    statusCode: 200,
                    httpVersion: "HTTP/1.1",
                    headerFields: [:]
                )!
                return (response, Data("ok".utf8))
            }
        }
        defer { MockURLProtocol.setHandler(for: url.absoluteString, handler: nil) }

        let client = RpcClient(session: .mockedWithProtocol(MockURLProtocol.self), logger: TestLogger())
        let result = await client.get(
            url: url,
            headers: [:],
            retrys: RetryParams(count: 1, delay: { 0 }),
            fileID: #fileID,
            functionName: #function,
            lineNumber: #line
        )

        switch result {
        case let .success(apiResponse):
            #expect(apiResponse.data?.utf8 == "ok")
            #expect(attempts == 2)
        case let .failure(error):
            #expect(Bool(false), "Expected retry to succeed, got \(error) (attempts: \(attempts))")
        }
    }

    @Test func getDoesNotRetryWhenConditionFails() async throws {
        let url = try #require(URL(string: "https://example.com/retry-skip"))
        var attempts = 0

        MockURLProtocol.setHandler(for: url.absoluteString) { _ in
            attempts += 1
            let response = HTTPURLResponse(url: url, statusCode: 500, httpVersion: "HTTP/1.1", headerFields: nil)!
            return (response, Data("err".utf8))
        }
        defer { MockURLProtocol.setHandler(for: url.absoluteString, handler: nil) }

        let client = RpcClient(session: .mockedWithProtocol(MockURLProtocol.self), logger: TestLogger())
        let result = await client.get(
            url: url,
            headers: [:],
            retrys: RetryParams(count: 2, delay: { 0 }, condition: { _ in false }),
            fileID: #fileID,
            functionName: #function,
            lineNumber: #line
        )

        #expect(attempts == 1)
        switch result {
        case .success:
            #expect(Bool(false), "Expected failure due to condition preventing retry")
        case let .failure(error):
            #expect(error.responseCode == 500 || error.responseCode == 0)
        }
    }

    @Test func getReturnsGenericErrorForTransportFailure() async throws {
        let url = try #require(URL(string: "https://example.com/transport-error"))
        struct Boom: Error {}

        MockURLProtocol.setHandler(for: url.absoluteString) { _ in
            throw Boom()
        }
        defer { MockURLProtocol.setHandler(for: url.absoluteString, handler: nil) }

        let client = RpcClient(session: .mockedWithProtocol(MockURLProtocol.self), logger: TestLogger())
        let result = await client.get(url: url)

        switch result {
        case .success:
            #expect(Bool(false), "Expected failure")
        case let .failure(error):
            #expect(error.responseCode == 0)
        }
    }

    @Test func headRequestExecutes() async throws {
        let urlString = "https://example.com/head-request"

        MockURLProtocol.setHandler(for: urlString) { request in
            #expect(request.httpMethod == "DELETE")
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)!
            return (response, Data())
        }
        defer { MockURLProtocol.setHandler(for: urlString, handler: nil) }

        let client = RpcClient(session: .mockedWithProtocol(MockURLProtocol.self), logger: TestLogger())
        let result = await client.head(path: urlString, headers: [:], queryParams: [:], fileID: #fileID, functionName: #function, lineNumber: #line)

        switch result {
        case let .success(response):
            #expect(response.code == 200)
        case let .failure(error):
            #expect(Bool(false), "Expected success, got \(error)")
        }
    }

    @Test func patchRequestExecutes() async throws {
        let urlString = "https://example.com/patch-request"
        let payload = Data("patch".utf8)

        MockURLProtocol.setHandler(for: urlString) { request in
            #expect(request.httpMethod == "PATCH")
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)!
            return (response, payload)
        }
        defer { MockURLProtocol.setHandler(for: urlString, handler: nil) }

        let client = RpcClient(session: .mockedWithProtocol(MockURLProtocol.self), logger: TestLogger())
        let endpoint = ApiEndpoint(path: urlString, type: .patch)
        let result = await client.performAsync(endpoint: endpoint, headers: [:], queryParams: [:], bodyData: payload)

        switch result {
        case let .success(response):
            #expect(response.data == payload)
        case let .failure(error):
            #expect(Bool(false), "Expected success, got \(error)")
        }
    }
}
