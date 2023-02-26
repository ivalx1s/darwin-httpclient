import Foundation

public typealias HeaderKey = String
public typealias HeaderValue = String
public typealias Headers = [HeaderKey: HeaderValue]
public typealias ParamKey = String
public typealias ParamValue = String
public typealias QueryParams = [ParamKey: ParamValue]
public typealias ResponseHeaders = [AnyHashable: Any]
public typealias ResponseCode = Int
public extension ResponseCode {
    var statusOK: Bool { self == 200 }
}
