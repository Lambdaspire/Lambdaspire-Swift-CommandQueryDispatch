# Lambdaspire Swift Command Query Dispatch

A lightweight Command Query Dispatch package for Swift.

You may also know this pattern as Command Query Responsibility Segregation / Separation (CQRS) or more simply Command Query Segregation / Separation (CQS).

Atomise your business logic and orchestration, maximise testability, and separate mutation from inquiry.

## Usage

### High Level

#### Standard Usage

The standard approach leverages `DependencyResolutionScope` and `Resolvable`.

Register the necessary components with any `DependencyRegistry`.

In this example we're using `ContainerBuilder` from the [Dependency Resolution package](https://github.com/Lambdaspire/Lambdaspire-Swift-DependencyResolution).

```swift
let builder: ContainerBuilder = .init()

builder
    .commandQueryDispatch()
    .standard(
        commandHandlers: [
            ExampleCommandHandler.self,
            OtherExampleCommandHandler.self,
            // ...
        ],
        queryHandlers: [
            ExampleQueryHandler.self,
            OtherExampleQueryHandler.self,
            // ...
        ])

// ...

let container = builder.build()
```

Retrieve a `CommandQueryDispatcher` to dispatch commands / queries.

Inline:

```swift
let dispatcher: CommandQueryDispatcher = container.resolve()

let info = try await dispatcher.dispatch(GetInfoQuery(subject: "Programming"))
``` 

In a `Resolvable` class:

```swift
@Resolvable
class ExampleModel {
    
    @Published private(set) var displayedError: Error? = nil
    
    private let dispatcher: CommandQueryDispatcher
    
    func addSomething() {
        Task {
            do {
                try await dispatcher.dispatch(AddSomethingCommand())
            } catch {
                displayedError = error
            }
        }
    }
}

// ...

// The dispatcher will be filled by dependency injection when the container resolves an ExampleModel instance.
let model: ExampleModel = container.resolve()

model.addSomething()
```

Define your commands, queries, and handlers as necessary.

Queries implement `CQDQuery`, and query handlers implement `HandlesQuery`.

```swift
struct GetInfoQuery : CQDQuery {
    typealias Value = MyInfoType
    
    var subject: String
}

@Resolvable
class GetInfoQueryHandler : HandlesQuery {

    private let api: Api
    private let analytics: AnalyticsEngine

    func handle(_ query: GetInfoQuery) async throws -> MyInfoType {
        
        analytics.logSearch(subject: query.subject)
        
        let result = try await api.get("/search?subject=\(subject)")
        
        analytics.logSearch(result: result)
        
        return result.info
    }
}
```

Commands implement `CQDCommand`, and command handlers implement `HandlesCommand`.

```swift
struct AddSomethingCommand : CQDCommand {
    // Empty is fine, but fill with data if you need.
}

@Resolvable
class AddSomethingCommandHandler : HandlesCommand {

    private let api: Api
    private let authorisation: AuthorisationEngine
    
    func handle(_ command: AddSomethingCommand) async throws {
        
        try await authorisation.ensureAuthorisation(to: .addSomething)
        
        try await api.post("/something")
    }
}
```

These very contrived examples demonstrate handlers orchestrating complex activity in isolated, reusable, testable components complete with dependency injection.

#### Non-Standard Usage

You can subvert the standardised approach if you want.

Create your own implementation of the `CommandQueryDispatcher` protocol and register it however you like. The standard implementation registers as `transient` but if your dispatcher is (for whatever reason) stateful you could sensibly register as `singleton` or `scoped`.

Register handlers however your dispatcher dictates.

```swift
class MySuperSpecialUniqueDispatcher : CommandQueryDispatcher {
    
    private let handlers: MyCustomHandlerRegistry
    
    init(handlers: MyCustomHandlerRegistry) {
        self.handlers = handlers
    }
    
    func dispatch<T>(_ command: T) async throws where T : CQDCommand {
        handlers.handle(command)
    }
    
    func dispatch<T>(_ query: T) async throws -> T.Value where T : CQDQuery {
        handlers.handle(query)
    }
}

// ...

let builder: ContainerBuilder = .init()

builder.transient { MySuperSpecialUniqueDispatcher(handlers: .whatever) }
```

It probably doesn't make a lot of sense to use this package if you're going to do this for production code, but it might be useful for test / preview scenarios.

### SwiftData

There's no reason you can't use SwiftData with this. You just need to find a way to inject a suitable `ModelContext` into your handlers.

Here's an naive end-to-end example using a few other Lambdaspire packages:

```swift

import SwiftUI
import SwiftData
import LambdaspireAbstractions
import LambdaspireSwiftUIFoundations
import LambdaspireDependencyResolution
import LambdaspireSwiftCommandQueryDispatch

@main
struct MyApp: App {
    
    private let modelContainer = getModelContainer()
    
    var body: some Scene {
        WindowGroup {
            IoCBootstrapperView {
                NavigationStack {
                    RootView()
                }
            }
        }
        .modelContainer(modelContainer)
    }
}

// ...

func getModelContainer() -> ModelContainer {
    
    let schema = Schema([
        SomeEntity.self
    ])
    
    let modelConfiguration = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: false,
        cloudKitDatabase: .private("iCloud.com.example.whatever"))

    return try! ModelContainer(
        for: schema,
        configurations: [modelConfiguration])
}


// ...

struct IoCBootstrapperView<Content: View> : View {
    
    var content: () -> Content
    
    @State private var rootScope: DependencyResolutionScope?
    
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        if let rootScope {
            content()
                .resolving(from: rootScope)
        } else {
            ProgressView()
                .task {
                    rootScope = getAppContainer(modelContext)
                }
        }
    }
}

// ...

func getAppContainer(_ modelContext: ModelContext) -> Container {
    let b: ContainerBuilder = .init()
    
    // SwiftData
    b.transient { modelContext }
    
    // Dispatcher
    b.commandQueryDispatch().standard(
        commandHandlers: [
            AddEntityCommandHandler.self
        ],
        queryHandlers: [
            GetRandomEntityQueryHandler.self
        ])
    
    // Scope
    b.transient { $0 }
    
    return b.build()
}

// ...

@Model
class SomeEntity {
    
    var name: String = ""
    
    init(name: String = "") {
        self.name = name
    }
}

// ...

struct AddEntityCommand : CQDCommand { }

@Resolvable
class AddEntityCommandHandler : HandlesCommand {
    
    private let modelContext: ModelContext
    
    func handle(_ command: AddEntityCommand) async throws {
        modelContext.insert(SomeEntity(name: "Entity \(Int.random(in: 100...999))"))
        try! modelContext.save()
    }
}

// ...

struct GetRandomEntityQuery : CQDQuery {
    typealias Value = SomeEntity
}

@Resolvable
class GetRandomEntityQueryHandler : HandlesQuery {
    
    private let modelContext: ModelContext
    
    func handle(_ query: GetRandomEntityQuery) async throws -> SomeEntity {
        guard let result = try modelContext.fetch(FetchDescriptor<SomeEntity>()).first else {
            throw DomainError.notFound
        }
        return result
    }
}

// ...

@ResolvedScope
struct RootView : View {

    @State private var random: SomeEntity?

    @Resolved private var dispatcher: CommandQueryDispatcher
    
    @Query private var entities: [SomeEntity]

    var body: some View {
        List {
            ForEach(entities, id: \.persistentModelID) { e in
                Text(e.name)
            }
        }
        .sheet(item: $random) { r in
            Text("Random: \(r.name)")
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task {
                        try! await dispatcher.dispatch(AddEntityCommand())
                    }
                } label: {
                    Text("Add")
                }
            }
            
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    Task { @MainActor in
                        random = try! await dispatcher.dispatch(GetRandomEntityQuery())
                    }
                } label: {
                    Text("View Random")
                }
            }
        }
    }
}

```
