import Foundation

public typealias HeaderKey = String
public typealias HeaderValue = String
public typealias Headers = [HeaderKey: HeaderValue]
public typealias ParamKey = String
public typealias ParamValue = String
public typealias QueryParams = [ParamKey: ParamValue]
public typealias ResponseHeaders = [String: Sendable]
public typealias ResponseCode = Int
public extension ResponseCode {
    var statusOK: Bool { self == 200 }
}

extension Dictionary where Key == AnyHashable, Value == Any {
    var asResponseHeaders: [String: Sendable] {
        self
            .reduce(into: ResponseHeaders()) { store, next in
                store[next.key.description] = next.value
            }
    }
}
