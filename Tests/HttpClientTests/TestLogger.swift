import Foundation
@testable import HttpClient

final class TestLogger: HttpClientLogging, @unchecked Sendable {
    private(set) var messages: [String] = []

    func log(_ message: String) {
        messages.append(message)
    }
}
