import Foundation
import Combine

public protocol IRpcClient: Actor,
    IRpcClientSync,
    IRpcClientWithCallback,
    IRpcClientWithPublisher,
    IRpcClientWithAsyncAwait {

}
