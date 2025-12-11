import Foundation
import Testing
@testable import HttpClient

@Suite struct DataNormalizationTests {
    @Test func stableNormalizedJSONStringIgnoresKeysDeeply() throws {
        let original = try #require(#"""
        {
            "id": 1,
            "meta": { "timestamp": "111", "device": "ios" },
            "name": "alex"
        }
        """#.data(using: .utf8))

        let other = try #require(#"""
        {
            "name": "alex",
            "meta": { "timestamp": "999", "device": "ios" },
            "id": 1
        }
        """#.data(using: .utf8))

        #expect(original.isStableJSONEqual(to: other, ignoringKeys: ["timestamp"], deep: true))

        let normalized = try original.stableNormalizedJSONString(ignoringKeys: ["timestamp"], deep: true)
        #expect(normalized == #"{"id":1,"meta":{"device":"ios"},"name":"alex"}"#)
    }

    @Test func stableNormalizedJSONStringRespectsDeepFlag() throws {
        let lhs = try #require(#"{ "data": { "ts": 1 } }"#.data(using: .utf8))
        let rhs = try #require(#"{ "data": { "ts": 2 } }"#.data(using: .utf8))

        #expect(lhs.isStableJSONEqual(to: rhs, ignoringKeys: ["ts"], deep: false) == false)
        #expect(lhs.isStableJSONEqual(to: rhs, ignoringKeys: ["ts"], deep: true))
    }
}
