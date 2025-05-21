import Foundation

extension PublishedStubbableWSClient {
    public struct Stub {
        public typealias Key = String
        public typealias MsgData = Data

        var key: Key { outgoingMsg.key }
        let outgoingMsg: OutgoingMsg
        let incomingMsgData: MsgData


        public init?(
            outgoingMsg: OutgoingMsg?,
            incomingMsgData: MsgData
        ) {
            guard let outgoingMsg = outgoingMsg
            else { return nil }

            self.outgoingMsg = outgoingMsg
            self.incomingMsgData = incomingMsgData
        }
    }
}

extension PublishedStubbableWSClient.Stub {
    public struct OutgoingMsg {
        let outgoingMsgData: MsgData
        let ignoringKeys: Set<String>
        let ignoringDeep: Bool
        let key: Key

        public init?(
            outgoingMsgData: MsgData,
            ignoringKeys: Set<String> = [],
            ignoringDeep: Bool = true
        ) {
            guard let key = try? outgoingMsgData.stableNormalizedJSONString(ignoringKeys: ignoringKeys, deep: ignoringDeep)
            else { return nil }

            self.outgoingMsgData = outgoingMsgData
            self.ignoringKeys = ignoringKeys
            self.ignoringDeep = ignoringDeep

            self.key = key
        }
    }
}
extension PublishedStubbableWSClient.Stub: Sendable {}
extension PublishedStubbableWSClient.Stub.OutgoingMsg: Sendable {}
