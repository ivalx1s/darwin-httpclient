public protocol IRpcAsyncClientStubbable: IRpcAsyncClient {
    func upsert(rule: ApiEndpoint, stub: ApiResponse) async
    func upsert(rules: [ApiEndpoint: ApiResponse]) async
    func remove(rule: ApiEndpoint) async
    func removeAllRules() async
}
