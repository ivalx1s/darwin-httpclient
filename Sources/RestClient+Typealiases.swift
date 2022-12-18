import Foundation

public typealias HeaderKey = String
public typealias HeaderValue = String
public typealias ParamKey = String
public typealias ParamValue = String
public typealias ResponseHeaders = [AnyHashable: Any]
public typealias ResponseCode = Int
public extension ResponseCode {
    var statusOK: Bool { self == 200 }
}
