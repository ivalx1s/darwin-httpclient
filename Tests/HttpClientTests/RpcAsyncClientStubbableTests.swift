import Foundation
import Testing
@testable import HttpClient

@Suite struct RpcAsyncClientStubbableTests {
    @Test func returnsStubWhenRuleMatches() async throws {
        let mock = RpcClientWithAsyncAwaitMock()
        let stubbable = RpcAsyncClientStubbable(client: mock, logger: TestLogger())

        let endpoint = ApiEndpoint(path: "https://example.com/stub", type: .get)
        let stubResponse = ApiResponse.stub(data: Data("stubbed".utf8), code: 201)
        await stubbable.upsert(rule: endpoint, stub: stubResponse)

        let result = await stubbable.get(
            url: try #require(URL(string: endpoint.path)),
            headers: [.authorization: .bearer(token: "token")],
            retrys: RetryParams(count: 1, delay: { 0 }),
            fileID: #fileID,
            functionName: #function,
            lineNumber: #line
        )

        switch result {
        case let .success(response):
            #expect(response.code == 201)
            #expect(response.data?.utf8 == "stubbed")
        case let .failure(error):
            #expect(Bool(false), "Expected stubbed response, got \(error)")
        }

        let recorded = await mock.getCalls
        #expect(recorded.isEmpty, "Underlying client should not be called when stub matches")
    }

    @Test func fallsBackToClientWhenNoStub() async throws {
        let mock = RpcClientWithAsyncAwaitMock()
        await mock.setGetResult(.success(.stub(data: Data("live".utf8))))
        let stubbable = RpcAsyncClientStubbable(client: mock, logger: TestLogger())

        let url = try #require(URL(string: "https://example.com/live"))
        _ = await stubbable.get(
            url: url,
            headers: [:],
            retrys: RetryParams(count: 0, delay: { 0 }),
            fileID: #fileID,
            functionName: #function,
            lineNumber: #line
        )

        let recorded = await mock.getCalls
        #expect(recorded.count == 1)
        #expect(recorded.first?.url == url)
    }
}
