import Foundation

extension Data {
    func normalizedJSON(removingKeys: Set<String>, deep: Bool) throws -> Any {
        let json = try JSONSerialization.jsonObject(with: self)

        func strip(_ object: Any, deep: Bool) -> Any {
            if let dict = object as? [String: Any] {
                let filtered = dict.filter { !removingKeys.contains($0.key) }
                let mapped = deep ? filtered.mapValues { strip($0, deep: true) } : filtered
                return mapped
            } else if let array = object as? [Any], deep {
                return array.map { strip($0, deep: true) }
            } else {
                return object
            }
        }

        return strip(json, deep: deep)
    }

    func stableNormalizedJSONString(ignoringKeys: Set<String> = [], deep: Bool = true) throws -> String {
        let normalized = try normalizedJSON(removingKeys: ignoringKeys, deep: deep)
        let data = try JSONSerialization.data(withJSONObject: normalized, options: [.sortedKeys])
        guard let string = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "stableJSONString", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid UTF-8"])
        }
        return string
    }

    func isStableJSONEqual(to other: Data, ignoringKeys: Set<String> = [], deep: Bool = true) -> Bool {
        do {
            let left = try self.stableNormalizedJSONString(ignoringKeys: ignoringKeys, deep: deep)
            let right = try other.stableNormalizedJSONString(ignoringKeys: ignoringKeys, deep: deep)
            return left == right
        } catch {
            return false
        }
    }
}

