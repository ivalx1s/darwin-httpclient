import Foundation

public typealias HeaderKey = String
public typealias HeaderValue = String
public typealias Headers = [HeaderKey: HeaderValue]
public typealias ParamKey = String
public typealias ParamValue = String
public typealias QueryParams = [ParamKey: ParamValue]
public typealias ResponseHeaders = [String: UncheckedSendableWrapper<Any>]
public typealias ResponseCode = Int
public typealias RequestRetrys = (count: UInt, delay: @Sendable () -> TimeInterval)

extension ResponseHeaders: Sendable {}
extension ResponseCode: Sendable {}

public extension ResponseCode {
    var statusOK: Bool { self == 200 }
    var statusCreated: Bool { self == 201 }
    var statusAccepted: Bool { self == 202 }
    var statusNoContent: Bool { self == 204 }
    var statusBadRequest: Bool { self == 400 }
    var statusUnauthorized: Bool { self == 401 }
    var statusForbidden: Bool { self == 403 }
    var statusNotFound: Bool { self == 404 }
    var statusConflict: Bool { self == 409 }
    var statusTooManyRequests: Bool { self == 429 }
    var statusInternalServerError: Bool { self == 500 }
    var statusServiceUnavailable: Bool { self == 503 }
    
    var isSuccess: Bool { (200...299).contains(self) }
    var isRedirection: Bool { (300...399).contains(self) }
    var isClientError: Bool { (400...499).contains(self) }
    var isServerError: Bool { (500...599).contains(self) }
}

extension Dictionary where Key == AnyHashable, Value == Any {
    var asResponseHeaders: [String: UncheckedSendableWrapper<Any>] {
        self
            .reduce(into: ResponseHeaders()) { store, next in
                store[next.key.description] = .init(payload: next.value)
            }
    }
}

public extension HeaderKey {
    // Common Header Keys
    static let contentType = "Content-Type"
    static let accept = "Accept"
    static let authorization = "Authorization"
    static let userAgent = "User-Agent"
    static let cacheControl = "Cache-Control"
    static let contentLength = "Content-Length"
    static let contentEncoding = "Content-Encoding"
    static let acceptEncoding = "Accept-Encoding"
    static let acceptLanguage = "Accept-Language"
    static let origin = "Origin"
    static let xRequestedWith = "X-Requested-With"
    static let ifMatch = "If-Match"
    static let ifNoneMatch = "If-None-Match"
    static let ifModifiedSince = "If-Modified-Since"
    static let ifUnmodifiedSince = "If-Unmodified-Since"
    static let contentDisposition = "Content-Disposition"
    
    // Security Headers
    static let xFrameOptions = "X-Frame-Options"
    static let xContentTypeOptions = "X-Content-Type-Options"
    static let xXSSProtection = "X-XSS-Protection"
    static let strictTransportSecurity = "Strict-Transport-Security"
    
    // Custom Headers
    static let apiKey = "X-API-Key"
    static let clientId = "X-Client-ID"
    static let requestId = "X-Request-ID"
    static let correlationId = "X-Correlation-ID"
}

public extension HeaderValue {
    // Content Types
    static let applicationJson = "application/json"
    static let applicationFormUrlEncoded = "application/x-www-form-urlencoded"
    static let applicationXml = "application/xml"
    static let textPlain = "text/plain"
    static let textHtml = "text/html"
    static let multipartFormData = "multipart/form-data"
    
    // Authorization
    static func basic(token: String) -> String {
        "Basic \(token)"
    }
    
    static func bearer(token: String) -> String {
        "Bearer \(token)"
    }
    
    // Cache Control
    static let noCache = "no-cache"
    static let noStore = "no-store"
    static let maxAge: @Sendable (Int) -> String = { (seconds: Int) in "max-age=\(seconds)" }
    static let mustRevalidate = "must-revalidate"
    
    // Content Encoding
    static let gzip = "gzip"
    static let deflate = "deflate"
    static let br = "br"
    
    // Security Headers
    static let nosniff = "nosniff"
    static let sameorigin = "SAMEORIGIN"
    static let denyAll = "DENY"
    
    // Content Disposition
    static func attachment(filename: String) -> String {
        "attachment; filename=\"\(filename)\""
    }
    static func inline(filename: String) -> String {
        "inline; filename=\"\(filename)\""
    }
}
