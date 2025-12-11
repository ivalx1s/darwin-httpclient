import Foundation
import Testing
@testable import HttpClient

@Suite struct HeadersAndErrorTests {
    @Test func headerValueHelpers() {
        #expect(HeaderValue.basic(token: "abc") == "Basic abc")
        #expect(HeaderValue.bearer(token: "xyz") == "Bearer xyz")
        #expect(HeaderValue.attachment(filename: "file.txt") == #"attachment; filename="file.txt""#)
    }

    @Test func responseHeadersConversion() {
        let raw: [AnyHashable: Any] = ["X-Test": "123"]
        let headers = raw.asResponseHeaders
        #expect(headers["X-Test"]?.payload as? String == "123")
    }

    @Test func apiErrorDataAndDescription() {
        let endpoint = ApiEndpoint(path: "https://example.com", type: .get)
        let error = ApiError(sender: "Test", endpoint: endpoint, responseCode: 400, message: "bad", data: Data("x".utf8))

        #expect(error.data["url"] == endpoint.path)
        #expect(error.responseCode == 400)
        #expect(error.conciseDescription.contains("400"))
    }
}
