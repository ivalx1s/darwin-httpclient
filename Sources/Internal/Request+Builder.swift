import Foundation

public protocol IRequestBuilder {
    static func buildRpcRequest(url: URL, type: ApiRequestType, headers: [HeaderKey: HeaderValue], bodyData: Data?) -> URLRequest
    static func buildWSRequest(url: URL, headers: [HeaderKey: HeaderValue]) -> URLRequest
    static func buildRequestUrl(path: String, queryParams: [ParamKey: ParamValue]) -> URL?
}

public struct RequestBuilder: IRequestBuilder {}

public extension IRequestBuilder {
    static func buildRpcRequest(url: URL, type: ApiRequestType, headers: [HeaderKey: HeaderValue], bodyData: Data?) -> URLRequest {
        var request = URLRequest(url: url)

        request.httpMethod = type.rawValue

        headers.forEach {
            request.setValue($0.value, forHTTPHeaderField: $0.key)
        }

        switch type {
        case .post, .put, .delete, .patch:
            request.httpBody = bodyData
        case .get, .head:
            break
        }

        return request
    }

    static func buildWSRequest(url: URL, headers: [HeaderKey: HeaderValue]) -> URLRequest {
        var request = URLRequest(url: url)

        headers.forEach {
            request.setValue($0.value, forHTTPHeaderField: $0.key)
        }

        return request
    }

    static func buildRequestUrl(path: String, queryParams: [ParamKey: ParamValue]) -> URL? {
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .rfc3986Unreserved) else {
            return nil
        }
        guard var urlComponents = URLComponents(string: encodedPath) else {
            return nil
        }

        if !queryParams.isEmpty {
            urlComponents.queryItems = queryParams
                    .sorted { $0.key < $1.key }
                    .map { URLQueryItem(name: $0.key, value: $0.value) }

            urlComponents.percentEncodedQuery = urlComponents.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        }

        return urlComponents.url
    }
}
