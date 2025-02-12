import Foundation

public extension ApiResponse {
    static func stub(data: Data?, code: Int = 200) -> Self {
        .init(
            data: data,
            headers: [:],
            code: code
        )
    }
}
