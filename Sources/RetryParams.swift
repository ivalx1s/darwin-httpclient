import Foundation

public struct RetryParams: Sendable {
    let count: UInt
    let delay: @Sendable () -> TimeInterval
    let condition: @Sendable (ApiError) -> Bool

    public init(
        count: UInt,
        delay: @Sendable @escaping () -> TimeInterval,
        condition: @Sendable @escaping (ApiError) -> Bool = { _ in true }
    ) {
        self.count = count
        self.delay = delay
        self.condition = condition
    }
}
