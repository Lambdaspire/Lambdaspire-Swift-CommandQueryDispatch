
import LambdaspireAbstractions

public protocol CQDQuery {
    associatedtype Value
}

public protocol HandlesQuery {
    associatedtype TQuery : CQDQuery
    func handle(_ : TQuery) async throws -> TQuery.Value
    static func register(_ : DependencyRegistry)
}

open class QueryHandler<T: CQDQuery> : HandlesQuery {
    public typealias TQuery = T
    
    public func handle(_ : TQuery) async throws -> TQuery.Value {
        fatalError("This must be overridden. Sorry.")
    }
    
    public static func register(_ registry: any DependencyRegistry) {
        registry.transient(QueryHandler<T>.self, assigned(Self.self))
    }
}
