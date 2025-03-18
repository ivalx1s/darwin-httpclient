public struct UncheckedSendableWrapper<T>: @unchecked Sendable {
    public let payload: T

    public init(payload: T) {
        self.payload = payload
    }
}

extension Dictionary where Value == UncheckedSendableWrapper<Any> {
    var payloads: [Key: Any] {
        return reduce(into: [:]) { result, element in
            result[element.key] = element.value.payload
        }
    }
}
