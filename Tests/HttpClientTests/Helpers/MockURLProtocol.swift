import Foundation

final class MockURLProtocol: URLProtocol {
    private final class HandlerBox {
        let lock = NSLock()
        var handlers: [String: (URLRequest) throws -> (HTTPURLResponse, Data?)] = [:]
    }

    private nonisolated(unsafe) static var handlerBox = HandlerBox()

    static func setHandler(for url: String, handler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?) {
        handlerBox.lock.lock()
        if let handler {
            handlerBox.handlers[url] = handler
        } else {
            handlerBox.handlers.removeValue(forKey: url)
        }
        handlerBox.lock.unlock()
    }

    private static func loadHandler(url: String) -> ((URLRequest) throws -> (HTTPURLResponse, Data?))? {
        handlerBox.lock.lock()
        let handler = handlerBox.handlers[url]
        handlerBox.lock.unlock()
        return handler
    }

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let requestURL = request.url?.absoluteString,
              let handler = Self.loadHandler(url: requestURL) else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            if let data {
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
