import Foundation
import Combine

public protocol IRpcClient:
    IRpcClientSync,
    IRpcClientWithCallback,
    IRpcClientWithPublisher,
    IRpcClientWithAsyncAwait {

}
