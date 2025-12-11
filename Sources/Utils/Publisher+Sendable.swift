import Combine

extension AnyPublisher: @retroactive @unchecked Sendable where Output: Sendable, Failure: Sendable {}
extension Published.Publisher: @retroactive @unchecked Sendable where Value: Sendable, Failure: Sendable {}
extension PassthroughSubject: @retroactive @unchecked Sendable where Output: Sendable, Failure: Sendable {}
