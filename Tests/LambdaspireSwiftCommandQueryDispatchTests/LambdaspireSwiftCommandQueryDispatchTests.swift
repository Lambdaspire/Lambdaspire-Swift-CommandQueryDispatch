import XCTest
import LambdaspireAbstractions
import LambdaspireDependencyResolution
import LambdaspireSwiftCommandQueryDispatch
import LambdaspireSwiftCommandQueryDispatch

final class LambdaspireSwiftCommandQueryDispatchTests: XCTestCase {
    
    private var dispatcher: CommandQueryDispatcher!
    
    func testHappyPath() async throws {
        
        let b: ContainerBuilder = .init()
        
        var valueModifiedByCommand: Int = 0
        
        b.singleton(TestValueCallback<Int>.self) { { valueModifiedByCommand = $0 } }
        
        b.commandQueryDispatch()
            .standard(
                commandHandlers: [TestCommandHandler.self],
                queryHandlers: [TestQueryHandler.self])
        
        let c = b.build()
        
        try await c.resolve(CommandQueryDispatcher.self).dispatch(TestCommand(value: 100))
        
        XCTAssertEqual(valueModifiedByCommand, 100)
        
        let queryResult = try await c.resolve(CommandQueryDispatcher.self).dispatch(TestQuery(input: 100))
        
        XCTAssertEqual(queryResult, 10000)
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
    override func handle(_ query: TestQuery) async throws -> Int {
        query.input * 100
    }
}

typealias TestValueCallback<T> = (T) -> Void
