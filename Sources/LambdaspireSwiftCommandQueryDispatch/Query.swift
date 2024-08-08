
import LambdaspireAbstractions

public protocol CQDQuery {
    associatedtype Value
}

public protocol HandlesQuery {
    associatedtype TQuery : CQDQuery
    func handle(_ : TQuery) async throws -> TQuery.Value
}
