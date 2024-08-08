
import LambdaspireAbstractions

public protocol CQDCommand { }

public protocol HandlesCommand {
    associatedtype TCommand : CQDCommand
    func handle(_ : TCommand) async throws
}
