import Foundation

internal extension Data {
	
	/// just a simple converter from a Data to a String
	var utf8: String? { String(data: self, encoding: .utf8) }
}
