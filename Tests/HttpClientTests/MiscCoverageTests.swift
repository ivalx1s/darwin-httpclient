import Combine
import Foundation
import Testing
@testable import HttpClient

@Suite struct MiscCoverageTests {
    @Test func apiRequestTypeDescriptionsArePadded() {
        #expect(ApiRequestType.get.description == "GET    ")
        #expect(ApiRequestType.post.description == "POST   ")
        #expect(ApiRequestType.patch.description == "PATCH  ")
    }

    @Test func apiEndpointFromFullEndpointBuildsUrl() throws {
        let full = ApiFullEndpoint(
            baseUrl: try #require(URL(string: "https://example.com")),
            path: "path/component",
            type: .delete
        )
        let endpoint = ApiEndpoint(from: full)

        #expect(endpoint.path == "https://example.com/path/component")
        #expect(endpoint.type == .delete)
        #expect(full.url.absoluteString == endpoint.path)
    }

    @Test func apiResponseHeaderLookupIsCaseInsensitive() {
        let response = ApiResponse(
            data: nil,
            headers: ["Content-TYPE": .init(payload: HeaderValue.applicationJson)],
            code: 200
        )

        #expect(response.headerValue(forKey: "content-type") == HeaderValue.applicationJson)
        #expect(response.headerValue(forKey: "missing") == nil)
    }

    @Test func apiErrorToStringContainsFields() {
        let error = ApiError(
            sender: "Tests",
            url: "https://example.com",
            responseCode: 418,
            message: "teapot",
            requestType: .get,
            headers: [.contentType: .applicationJson],
            params: ["q": "1"]
        )

        let stringified = error.toString()
        #expect(stringified.contains("responseCode: 418"))
        #expect(stringified.contains("url: https://example.com"))
        #expect(error.conciseDescription.contains("418"))
    }

    @Test func rpcClientCurlBuilderFormatsRequest() throws {
        let url = try #require(URL(string: "https://example.com/api"))
        let curl = RpcClient.create_cURL(
            requestType: .post,
            path: url,
            headers: [.contentType: .applicationJson, .authorization: .bearer(token: "t")],
            bodyData: Data("body".utf8)
        )

        #expect(curl.contains("POST"))
        #expect(curl.contains("Content-Type: application/json"))
        #expect(curl.contains("Authorization: Bearer t"))
        #expect(curl.contains("body"))
    }

    @Test func stringifyDataDropsHtmlPrefix() {
        let client = RpcClient(session: URLSession(configuration: .ephemeral), logger: TestLogger())
        let cleaned = client.stringifyData(data: Data("<!doctype html><html>ok</html>".utf8))
        #expect(cleaned == "<html>ok</html>")
        #expect(client.stringifyData(data: nil).isEmpty)
    }

    @Test func safeUrlQueryAllowedEncodesPlus() {
        #expect("+".addingPercentEncoding(withAllowedCharacters: .safeURLQueryAllowed) == "%2B")
        #expect("-".addingPercentEncoding(withAllowedCharacters: .safeURLQueryAllowed) == "-")
    }

    @Test func asyncSinkPropagatesValues() async throws {
        let subject = PassthroughSubject<Int, Never>()
        let recorder = Recorder()
        let cancellable = subject.sink { value in
            await recorder.append(value)
        }

        subject.send(1)
        subject.send(2)
        cancellable.cancel()

        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(await recorder.values == [1, 2])
    }

    @Test func responseCodeCoversAdditionalFlags() {
        #expect(ResponseCode(200).statusOK)
        #expect(ResponseCode(201).statusCreated)
        #expect(ResponseCode(202).statusAccepted)
        #expect(ResponseCode(204).statusNoContent)
        #expect(ResponseCode(500).isServerError)
    }

    @Test func defaultLoggerDoesNotCrash() {
        DefaultLogger.shared.log("coverage")
    }

    @Test func responseCodeAdditionalFlags() {
        #expect(ResponseCode(401).statusUnauthorized)
        #expect(ResponseCode(403).statusForbidden)
        #expect(ResponseCode(404).statusNotFound)
        #expect(ResponseCode(409).statusConflict)
        #expect(ResponseCode(500).statusInternalServerError)
        #expect(ResponseCode(503).statusServiceUnavailable)
        #expect(ResponseCode(302).isRedirection)
    }
}

actor Recorder {
    private(set) var values: [Int] = []

    func append(_ value: Int) {
        values.append(value)
    }
}
