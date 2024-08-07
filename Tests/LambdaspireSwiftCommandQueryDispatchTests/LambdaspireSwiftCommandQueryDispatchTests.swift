import XCTest
import LambdaspireAbstractions
import LambdaspireDependencyResolution
import LambdaspireSwiftCommandQueryDispatch
@testable import LambdaspireSwiftCommandQueryDispatch

final class LambdaspireSwiftCommandQueryDispatchTests: XCTestCase {
    
    private var dispatcher: CommandQueryDispatcher!
    
    func testExample() async throws {
        
        let b: ContainerBuilder = .init()
        
        var value: Int = 0
        
        b.singleton(TestValueCallback<Int>.self) {
            {
                value = $0
            }
        }
        
        b.commandQueryDispatch().standard(
            commandHandlers: [TestCommandHandler.self],
            queryHandlers: [TestQueryHandler.self])
        
        let c = b.build()
        
        try await c.resolve(CommandQueryDispatcher.self).dispatch(TestCommand(value: 100))
        
        XCTAssertEqual(value, 100)
        
        let queryValue = try await c.resolve(CommandQueryDispatcher.self).dispatch(TestQuery(input: 100))
        
        XCTAssertEqual(queryValue, 10000)
    }
}

struct TestCommand : CQDCommand {
    var value: Int
}

@Resolvable
class TestCommandHandler : CommandHandler<TestCommand> {
    
    let callback: TestValueCallback<Int>
    
    override func handle(_ command: TestCommand) async throws {
        callback(command.value)
    }
}

struct TestQuery : CQDQuery {
    typealias Value = Int
    
    var input: Int
}

@Resolvable
class TestQueryHandler : QueryHandler<TestQuery> {
    override func handle(_ command: QueryHandler<TestQuery>.TQuery) async throws -> Int {
        command.input * 100
    }
}

typealias TestValueCallback<T> = (T) -> Void
