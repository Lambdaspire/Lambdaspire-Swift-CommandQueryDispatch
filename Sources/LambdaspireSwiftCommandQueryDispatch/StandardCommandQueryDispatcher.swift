
import LambdaspireAbstractions

class StandardCommandQueryDispatcher : CommandQueryDispatcher, Resolvable {
    
    private let scope: DependencyResolutionScope
    
    required init(scope: DependencyResolutionScope) {
        self.scope = scope
    }
    
    func dispatch<T>(_ command: T) async throws where T : CQDCommand {
        try await scope.resolve(CommandHandler<T>.self).handle(command)
    }
    
    func dispatch<T>(_ query: T) async throws -> T.Value where T : CQDQuery {
        try await scope.resolve(QueryHandler<T>.self).handle(query)
    }
}

struct CommandHandler<T: CQDCommand> {
    var handle: (T) async throws -> Void
}

struct QueryHandler<T: CQDQuery> {
    var handle: (T) async throws -> T.Value
}
