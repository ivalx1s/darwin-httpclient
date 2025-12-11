import Testing
@testable import HttpClient

@Suite struct ResponseHelpersTests {
    @Test func apiResponseHeaderLookupUsesPayloads() {
        let response = ApiResponse(
            data: nil,
            headers: ["Content-Type": UncheckedSendableWrapper(payload: "text/plain")],
            code: 200
        )

        #expect(response.headerValue(forKey: "content-type") == "text/plain")
        #expect(response.headers.payloads["Content-Type"] as? String == "text/plain")
    }

    @Test func responseCodeConvenienceFlags() {
        let code: ResponseCode = 429

        #expect(code.isClientError)
        #expect(code.isSuccess == false)
        #expect(code.statusTooManyRequests)
    }
}
