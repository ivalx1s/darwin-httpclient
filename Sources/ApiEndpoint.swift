import Foundation

public struct ApiEndpoint: Sendable, Hashable {
    public let path: String
    public let type: ApiRequestType
    
    public init(
        path: String,
        type: ApiRequestType
    ) {
        self.path = path
        self.type = type
    }
    
    init(from apiFullEndpoint: ApiFullEndpoint) {
        self.path = apiFullEndpoint.url.absoluteString
        self.type = apiFullEndpoint.type
    }
}

#warning("Refactor library to use proper endpoint semantics")
// in ApiEndpoint path should be path component not including base url
public struct ApiFullEndpoint {
    public let baseUrl: URL
    public let path: String
    public let type: ApiRequestType
    
    public init(
        baseUrl: URL,
        path: String,
        type: ApiRequestType
    ) {
        self.baseUrl = baseUrl
        self.path = path
        self.type = type
    }
    
    public var url: URL {
        return baseUrl.appendingPathComponent(path)
    }
}
