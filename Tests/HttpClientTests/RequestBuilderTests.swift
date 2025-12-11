import Foundation
import Testing
@testable import HttpClient

@Suite struct RequestBuilderTests {
    @Test func buildRequestUrlEncodesQueryAndPreservesPlus() {
        let url = RequestBuilder.buildRequestUrl(
            path: "https://example.com/phone+number",
            queryParams: [
                "q": "+value",
                "space": "a b"
            ]
        )

        #expect(url?.absoluteString == "https://example.com/phone%2Bnumber?q=%2Bvalue&space=a%20b")
    }

    @Test func buildRpcRequestSetsMethodHeadersAndBody() throws {
        let url = try #require(URL(string: "https://example.com/upload"))
        let body = Data("payload".utf8)
        let request = RequestBuilder.buildRpcRequest(
            url: url,
            type: .post,
            headers: [.contentType: .applicationJson],
            bodyData: body
        )

        #expect(request.httpMethod == ApiRequestType.post.rawValue)
        #expect(request.value(forHTTPHeaderField: HeaderKey.contentType) == HeaderValue.applicationJson)
        #expect(request.httpBody == body)
    }

    @Test func buildWSRequestCopiesHeaders() throws {
        let url = try #require(URL(string: "wss://example.com/socket"))
        let request = RequestBuilder.buildWSRequest(url: url, headers: [.authorization: HeaderValue.bearer(token: "t")])

        #expect(request.url == url)
        #expect(request.value(forHTTPHeaderField: HeaderKey.authorization) == HeaderValue.bearer(token: "t"))
    }
}
