public enum ApiRequestType: String, CustomStringConvertible, Sendable, Hashable {
    case get    = "GET"
    case post   = "POST"
    case put    = "PUT"
    case delete = "DELETE"
    case head   = "HEAD"
    case patch = "PATCH"

    public var description: String {
        switch self {
        case .get:
            return "GET    "
        case .post:
            return "POST   "
        case .put:
            return "PUT    "
        case .delete:
            return "DELETE "
        case .head:
            return "HEAD   "
        case .patch:
            return "PATCH  "
        }
    }

}
