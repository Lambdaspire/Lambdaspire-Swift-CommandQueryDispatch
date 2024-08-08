
import LambdaspireAbstractions

public protocol CQDCommand { }

public protocol HandlesCommand {
    associatedtype TCommand
    func handle(_ : TCommand) async throws
    static func register(_ : DependencyRegistry)
}

open class CommandHandler<T: CQDCommand> : HandlesCommand {
    
    public typealias TCommand = T
    
    open func handle(_ : T) async throws { }
    
    public static func register(_ registry: any DependencyRegistry) {
        registry.transient(CommandHandler<T>.self, assigned(Self.self))
    }
}
