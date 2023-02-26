import Foundation
import Combine

public protocol IRpcClient:
    IRestClientSync,
    IRpcClientWithCallback,
    IRpcClientWithPublisher,
    IRpcClientWithAsyncAwait {

}
