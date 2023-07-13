public class Domain {
    // MARK: Lifecycle

    public init(_ name: String, parent: Domain? = nil) {
        self.name = name
        self.parent = parent

        self.graphite = Node(name: name, kind: .domain, priority: .child)

        if let parent {
            forward(from: eventCreated, to: parent.eventCreated)
            forward(from: storeCreated, to: parent.storeCreated)
            forward(from: domainCreated, to: parent.domainCreated)
        }

        eventCreated.watch { unit in
            if let onCreate = self.onCreateEvent {
                onCreate(unit)
            }
        }

        storeCreated.watch { unit in
            if let onCreate = self.onCreateStore {
                onCreate(unit)
            }
        }

        domainCreated.watch { unit in
            if let onCreate = self.onCreateDomain {
                onCreate(unit)
            }
        }
    }

    // MARK: Public

    public var graphite: Node
    public let name: String

    public let eventCreated = Event<AnyEvent>()
    public let storeCreated = Event<AnyStore>()
    public let domainCreated = Event<Domain>()

    public var onCreateEvent: ((_ event: AnyEvent) -> Void)?
    public var onCreateStore: ((_ store: AnyStore) -> Void)?
    public var onCreateDomain: ((_ domain: Domain) -> Void)?

    public let parent: Domain?

    public var kind: String { "domain" }
}
