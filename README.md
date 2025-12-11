## HttpClient (darwin-httpclient)

Lightweight networking toolkit with `async/await`, Combine, callback APIs, WebSockets, and built-in stubbing. Minimum platforms: iOS 13, watchOS 6, macOS 11, tvOS 13.

### Installation (Swift Package Manager)
- In your `Package.swift` add:
```swift
.package(url: "https://github.com/<your-org>/darwin-httpclient.git", from: "1.0.0")
```
- Link the product: `.product(name: "HttpClient", package: "darwin-httpclient")`.

### Quick Start (HTTP)
```swift
let client = RpcClient()
let endpoint = ApiEndpoint(path: "https://api.example.com/users", type: .get)
let result = await client.performAsync(
    endpoint: endpoint,
    headers: [.authorization: .bearer(token: "token")],
    queryParams: ["page": "1"],
    bodyData: nil
)
```
- Combine: `RpcClient().get(path: "...", headers: [:], queryParams: [:])` returns `AnyPublisher<ApiResponse, ApiError>`.
- Callbacks: use `IRpcCompletionClient` methods.
- Retries: pass `RetryParams(count: 3, delay: { 1.0 })` to `performAsync`/`get` for automatic retry logic.

### WebSockets
- Prefer `PublishedWSClient`: publishes incoming messages and connection state via Combine, keeps the connection alive (`pingInterval`), and auto-reconnects (`reconnectInterval`). `WSClient` is experimental.

### Stubbing
- HTTP: wrap real clients with `RpcAsyncClientStubbable(client: RpcClient())`; manage rules mapping `ApiEndpoint` → `ApiResponse` via `upsert` and `removeAllRules`.
- WebSocket: `PublishedStubbableWSClient` lets you stub responses for outgoing messages. JSON bodies can be normalized with `Data.stableNormalizedJSONString`.

### Logging
All clients accept any `HttpClientLogging`; default is `DefaultLogger.shared`. Inject your own logger for production.

### Session Config & SSL
- Build `URLSessionConfiguration` quickly with `ApiSessionConfigBuilder.buildConfig(timeoutForResponse:timeoutResourceInterval:disableCookieStorage:)`.
- TLS pinning helpers live in `Sources/SSLPinning/`; extend `CertVerificationChallenge` with your pinned certificates.

### Testing
- Default: `swift test` (Swift Testing).
- Coverage: `swift test --enable-code-coverage`.
- iOS sim: find a booted device ID with `xcrun simctl list devices | rg Booted`, then run:
```bash
xcodebuild test -scheme darwin-httpclient -destination "id=<SIM_ID>" -sdk iphonesimulator -skipPackagePluginValidation
```
