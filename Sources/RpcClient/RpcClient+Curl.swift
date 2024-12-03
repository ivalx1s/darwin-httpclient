import Foundation

extension RpcClient {
    static func create_cURL(requestType: ApiRequestType, path: URL, headers: [HeaderKey: HeaderValue], bodyData: Data?) -> String {
        let string = """
                     curl -vX "\(requestType.rawValue)" "\(path.description)" \\
                          \(headers.map {"-H '\($0.key): \($0.value)'"}.joined(separator: "\\\n     "))\\
                          -d $'\(bodyData?.utf8 ?? "")'
                     """
        return string
    }
}
