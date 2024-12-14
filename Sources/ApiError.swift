import Foundation


public struct ApiError: Sendable, Error {
    public let violation: ErrorViolation
    public let sender: Any.Type?
    public let message: String
    public let rawData: Data?
    public let callStack: [String]
    public let error: Error?
    public let url: String
    public let responseCode: Int
    public let requestType: ApiRequestType
    public let headers: [HeaderKey: HeaderValue]
    public let params: [ParamKey: ParamValue]
	public let responseHeaders: ResponseHeaders

    public var conciseDescription: String {
        "\(responseCode): \(violation) from \(sender ?? "unknown sender" as Any); \(message)"
    }

    public var description: String {
        conciseDescription
    }

    public var debugDescription: String {
        conciseDescription
    }
    
    public init(
            sender: Any? = nil,
            endpoint: ApiEndpoint,
            responseCode: Int = 0,
            message: String = "",
            data: Data? = nil,
            violation: ErrorViolation = .warning,
            error: Error? = nil,
            headers: Headers = [:],
            params: QueryParams = [:],
			responseHeaders: ResponseHeaders = [:]
    ) {
        self.init(
                sender: sender,
                url: endpoint.path,
                responseCode: responseCode,
                message: message,
                data: data,
                violation: violation,
                error: error,
                requestType: endpoint.type,
                headers: headers,
                params: params,
				responseHeaders: responseHeaders
        )
    }

    public init(
            sender: Any? = nil,
            url: String = "",
            responseCode: Int = 0,
            message: String = "",
            data: Data? = nil,
            violation: ErrorViolation = .warning,
            error: Error? = nil,
            requestType: ApiRequestType,
            headers: Headers = [:],
            params: QueryParams = [:],
			responseHeaders: ResponseHeaders = [:]
    ) {
        self.sender = Mirror(reflecting: sender ?? "unknwon sender" as Any).subjectType
        self.url = url
        self.responseCode = responseCode
        self.message = message
        self.rawData = data
        self.violation = violation
        self.callStack = [] // Thread.callStackSymbols
        self.headers = headers
        self.params = params
        self.error = error
        self.requestType = requestType
		self.responseHeaders = responseHeaders
    }

    public func toString() -> String {
        data.map { "\($0.key): \($0.value)" }.joined(separator: "\n");
    }

    public var data: [String: String] {
        [
            "sender": "\(sender ?? "unknown sender" as Any)",
            "url": url,
            "type": "\(requestType.rawValue)",
            "responseCode": "\(responseCode)",
            "message": message,
            "violation": violation.rawValue,
            "cause": error?.localizedDescription ?? "",
            "callStack": "\n\(callStack.joined(separator: "\n"))"
        ]
    }
}

public extension ApiError {
    enum ErrorViolation: String, Sendable {
		
		/// some problems with authentication
		case authProblem = "AuthProblem"
		
		/// nothing special, we can ignore it and don't care
		case silent = "Silent"
		
		/// something went wrong and we have to log it without any user reaction
		case warning = "Warning"
		
		/// something serious went wrong, we have to log it and notify user
		case error = "Error"
		
		/// something critical was happen, we have to log it and relaunch app
		case fatal = "Fatal"
	}
}

