
import LambdaspireAbstractions

public extension DependencyRegistry {
    func commandQueryDispatch() -> CommanQueryDispatchRegistrator {
        .init(registry: self)
    }
}

public class CommanQueryDispatchRegistrator {
    
    private let registry: any DependencyRegistry
    
    init(registry: any DependencyRegistry) {
        self.registry = registry
    }
    
    @discardableResult public func dispatcher<T: CommandQueryDispatcher & Resolvable>(_ : T.Type) -> Self {
        registry.transient(CommandQueryDispatcher.self, assigned(T.self))
        return self
    }
    
    @discardableResult public func handler<T: HandlesCommand & Resolvable>(_ : T.Type) -> Self {
        registry.transient(T.self)
        T.register(registry)
        return self
    }
    
    @discardableResult public func handler<T: HandlesQuery & Resolvable>(_ : T.Type) -> Self {
        registry.transient(T.self)
        T.register(registry)
        return self
    }
    
    public func standard(
        commandHandlers: [any (HandlesCommand & Resolvable).Type],
        queryHandlers: [any (HandlesQuery & Resolvable).Type]) {
            dispatcher(StandardCommandQueryDispatcher.self)
            commandHandlers.forEach { handler($0) }
            queryHandlers.forEach { handler($0) }
        }
}
