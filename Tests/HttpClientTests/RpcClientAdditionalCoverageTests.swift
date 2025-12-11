import Combine
import Foundation
import Testing
@testable import HttpClient

@Suite(.serialized) struct RpcClientAdditionalCoverageTests {
    @Test func asyncPostHandlesNoContent() async throws {
        let urlString = "https://example.com/async-204"
        let body = Data("payload".utf8)

        MockURLProtocol.setHandler(for: urlString) { request in
            #expect(request.httpMethod == "POST")
            let response = HTTPURLResponse(url: request.url!, statusCode: 204, httpVersion: "HTTP/1.1", headerFields: ["X-Flag": "1"])!
            return (response, nil)
        }
        defer { MockURLProtocol.setHandler(for: urlString, handler: nil) }

        let client = RpcClient(session: .mockedWithProtocol(MockURLProtocol.self), logger: TestLogger())
        let endpoint = ApiEndpoint(path: urlString, type: .post)
        let result = await client.performAsync(
            endpoint: endpoint,
            headers: [:],
            queryParams: [:],
            bodyData: body,
            retrys: (count: 0, delay: { 0 }),
            fileID: #fileID,
            functionName: #function,
            lineNumber: #line
        )

        switch result {
        case let .success(response):
            #expect(response.code == 204)
            #expect(response.data == nil)
        case let .failure(error):
            #expect(Bool(false), "Expected 204 success, got \(error)")
        }
    }

    @Test func asyncGetFailsForNonHttpResponse() async throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [NonHTTPURLProtocol.self]
        let session = URLSession(configuration: config)
        let client = RpcClient(session: session, logger: TestLogger())

        let result = await client.get(path: "https://example.com/non-http", headers: [:], queryParams: [:], fileID: #fileID, functionName: #function, lineNumber: #line)

        switch result {
        case .success:
            #expect(Bool(false), "Expected failure for non-HTTP response")
        case let .failure(error):
            #expect(error.responseCode == 0)
        }
    }

    @Test func publisherMapsUnknownError() async {
        let urlString = "https://example.com/pub-unknown"
        struct DummyError: Error {}
        MockURLProtocol.setHandler(for: urlString) { _ in
            throw DummyError()
        }
        defer { MockURLProtocol.setHandler(for: urlString, handler: nil) }

        let client = RpcClient(session: .mockedWithProtocol(MockURLProtocol.self), logger: TestLogger())
        let publisher = (client as IRpcPublisherClient).get(path: urlString, headers: [:], queryParams: [:])
        let result = await firstPublisherResult(publisher)

        switch result {
        case let .failure(error):
            #expect(error.responseCode == 0)
        case .success:
            #expect(Bool(false), "Expected failure from thrown error")
        case .none:
            #expect(Bool(false), "Publisher did not emit")
        }
    }

    @Test func syncDeleteReturnsNoContent() throws {
        let urlString = "https://example.com/sync-204"
        MockURLProtocol.setHandler(for: urlString) { request in
            #expect(request.httpMethod == "DELETE")
            let response = HTTPURLResponse(url: request.url!, statusCode: 204, httpVersion: "HTTP/1.1", headerFields: ["X-Sync": "1"])!
            return (response, nil)
        }
        defer { MockURLProtocol.setHandler(for: urlString, handler: nil) }

        let client = RpcClient(session: .mockedWithProtocol(MockURLProtocol.self), logger: TestLogger())
        let result: Result<ApiResponse, ApiError> = client.delete(path: urlString, headers: [:], queryParams: [:], bodyData: nil)

        switch result {
        case let .success(response):
            #expect(response.code == 204)
            #expect(response.data == nil)
            #expect(response.headers.payloads["X-Sync"] as? String == "1")
        case let .failure(error):
            #expect(Bool(false), "Expected success, got \(error)")
        }
    }

    @Test func callbackFailsWhenTransportFails() async {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [ErrorURLProtocol.self]
        let session = URLSession(configuration: config)
        let client = RpcClient(session: session, logger: TestLogger())

        let result = await withCheckedContinuation { (continuation: CheckedContinuation<Result<ApiResponse, ApiError>, Never>) in
            let box = ResumeBox()

            client.get(path: "https://example.com/callback-error", headers: [:], queryParams: [:]) { _ in
                box.resume(.success(ApiResponse(data: nil)), continuation: continuation)
            } onFail: { apiError in
                box.resume(.failure(apiError), continuation: continuation)
            }
        }

        switch result {
        case .success:
            #expect(Bool(false), "Expected transport error")
        case let .failure(error):
            #expect(error.responseCode == 0)
        }
    }
}

private func firstPublisherResult<T: Sendable>(_ publisher: some Publisher<T, ApiError>) async -> Result<T, ApiError>? {
    await withCheckedContinuation { continuation in
        var cancellable: AnyCancellable?
        cancellable = publisher.sink { completion in
            if case let .failure(error) = completion {
                cancellable?.cancel()
                continuation.resume(returning: .failure(error))
            }
        } receiveValue: { value in
            cancellable?.cancel()
            continuation.resume(returning: .success(value))
        }
    }
}

private final class NonHTTPURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        let response = URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

private final class ErrorURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        client?.urlProtocol(self, didFailWithError: URLError(.cannotConnectToHost))
    }
    override func stopLoading() {}
}

private final class ResumeBox: @unchecked Sendable {
    private let lock = NSLock()
    private var resumed = false

    func resume(_ value: Result<ApiResponse, ApiError>, continuation: CheckedContinuation<Result<ApiResponse, ApiError>, Never>) {
        lock.lock(); defer { lock.unlock() }
        guard !resumed else { return }
        resumed = true
        continuation.resume(returning: value)
    }
}
