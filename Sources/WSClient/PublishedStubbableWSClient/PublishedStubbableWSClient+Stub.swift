import Foundation

extension PublishedStubbableWSClient {
    public struct Stub {
        public typealias Key = String
        public typealias IncomingMsgData = Data
        public typealias StubbedOutgoingMsgData = Data

        let key: Key
        let outgoingMsgStub: StubbedOutgoingMsgData
        let ignoringKeys: Set<String>
        let ignoringDeep: Bool

        public init?(
            incomingMsgData: IncomingMsgData,
            outgoingMsgStub: StubbedOutgoingMsgData,
            ignoringKeys: Set<String> = [],
            ignoringDeep: Bool = true
        ) {
            guard let key = try? incomingMsgData.stableNormalizedJSONString(ignoringKeys: ignoringKeys, deep: ignoringDeep)
            else { return nil }

            self.key = key
            self.outgoingMsgStub = outgoingMsgStub
            self.ignoringKeys = ignoringKeys
            self.ignoringDeep = ignoringDeep
        }
    }
}

extension PublishedStubbableWSClient.Stub: Sendable {}
