
import LambdaspireAbstractions

public protocol CommandQueryDispatcher {
    func dispatch<T: CQDCommand>(_ : T) async throws
    func dispatch<T: CQDQuery>(_ : T) async throws -> T.Value
}
