import Combine
import Foundation
import Testing
@testable import HttpClient

@Suite(.serialized) struct RpcClientPublisherTests {
    @Test func publisherSuccess() async {
        let urlString = "https://example.com/pub"
        MockURLProtocol.setHandler(for: urlString) { request in
            #expect(request.url?.absoluteString == urlString)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)!
            return (response, Data("pub-ok".utf8))
        }
        defer { MockURLProtocol.setHandler(for: urlString, handler: nil) }

        let client = RpcClient(session: .mockedWithProtocol(MockURLProtocol.self), logger: TestLogger())
        let publisher = (client as IRpcPublisherClient).get(path: urlString, headers: [:], queryParams: [:])
        let result = await firstResult(publisher)

        switch result {
        case let .success(apiResponse):
            #expect(apiResponse.code == 200)
            #expect(apiResponse.data?.utf8 == "pub-ok")
        case let .failure(error):
            #expect(Bool(false), "Expected success, got \(error)")
        case .none:
            #expect(Bool(false), "No value emitted")
        }
    }

    @Test func publisherFailure() async {
        let urlString = "https://example.com/pub-fail"
        MockURLProtocol.setHandler(for: urlString) { request in
            #expect(request.url?.absoluteString == urlString)
            let response = HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: "HTTP/1.1", headerFields: ["X-Reason": "missing"])!
            return (response, Data("nope".utf8))
        }
        defer { MockURLProtocol.setHandler(for: urlString, handler: nil) }

        let client = RpcClient(session: .mockedWithProtocol(MockURLProtocol.self), logger: TestLogger())
        let publisher = (client as IRpcPublisherClient).get(path: urlString, headers: [:], queryParams: [:])
        let result = await firstResult(publisher)

        switch result {
        case let .failure(error):
            #expect(error.responseCode == 404)
            #expect(error.responseHeaders["X-Reason"]?.payload as? String == "missing")
        case .success:
            #expect(Bool(false), "Expected failure")
        case .none:
            #expect(Bool(false), "No value emitted")
        }
    }
}

private func firstResult<T: Sendable>(_ publisher: some Publisher<T, ApiError>) async -> Result<T, ApiError>? {
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
