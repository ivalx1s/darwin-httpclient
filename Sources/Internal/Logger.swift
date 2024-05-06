import os.log
import Foundation


internal extension os.Logger {
    /// A logger instance that logs to '🔤Default' category within host app subsystem.
	static let `default` = os.Logger(subsystem: bundle.bundleIdentifier!, category: "🔤Default")
    static let api = os.Logger(subsystem: Bundle.main.bundleIdentifier!, category: "↕️ API")
    static let challenge = os.Logger(subsystem: Bundle.main.bundleIdentifier!, category: "🔑️ Challenge")
}

/// A proxy type to work around apple os log [limitations](https://stackoverflow.com/questions/62675874/xcode-12-and-oslog-os-log-wrapping-oslogmessage-causes-compile-error-argumen#63036815).
///
///
internal enum _OSLogPrivacy: Equatable {
    case  auto, `public`, `private`, sensitive
}

internal func log(
    _ message: String,
    logType: OSLogType = .default,
    category: os.Logger = .default,
    privacy: _OSLogPrivacy = .private,
    includeCallerLocation: Bool = true,
    fileID: String = #fileID,
    functionName: String = #function,
    lineNumber: Int = #line
) {
    
    var message = message
    if includeCallerLocation {
        let moduleAndFileName = fileID.replacingOccurrences(of: ".swift", with: "")
        let moduleName = String("\(fileID)".prefix(while: { $0 != "/" }))
        let fileName = moduleAndFileName
            .split(separator: "/")
            .suffix(1)
            .description
            .replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "]", with: "")
        let logLocationDescription = "\(lineNumber):\(moduleName).\(fileName).\(functionName)"
        message = "\(message) \n> location: \(logLocationDescription)"
    }
    
    // privacy argument must be resolved on compile time, hence ugly workaround
    // more info:
    // https://stackoverflow.com/questions/62675874/xcode-12-and-oslog-os-log-wrapping-oslogmessage-causes-compile-error-argumen#63036815
    switch privacy {
    case .private:
        category.log(level: logType, "\(message, align: .left(columns: 30), privacy: .private)")
    case .public:
        category.log(level: logType, "\(message, align: .left(columns: 30), privacy: .public)")
    case .auto:
        category.log(level: logType, "\(message, align: .left(columns: 30), privacy: .auto)")
    case .sensitive:
        category.log(level: logType, "\(message, align: .left(columns: 30), privacy: .sensitive)")
    }
}


internal extension os.Logger {
	
	class BundleAccessor {}
	
	static var bundle: Bundle {
		Bundle(for: BundleAccessor.self)
	}
	
}
