import Testing
@testable import HttpClient

@Suite struct ApiSessionConfigBuilderTests {
    @Test func buildConfigSetsTimeouts() {
        let config = ApiSessionConfigBuilder.buildConfig(
            timeoutForResponse: 15,
            timeoutResourceInterval: 45
        )

        #expect(config.timeoutIntervalForRequest == 15)
        #expect(config.timeoutIntervalForResource == 45)
    }

    @Test func buildConfigCanDisableCookies() {
        let config = ApiSessionConfigBuilder.buildConfig(
            timeoutForResponse: 10,
            timeoutResourceInterval: 20,
            disableCookieStorage: true
        )

        #expect(config.httpCookieStorage == nil)
    }
}
