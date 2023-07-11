public class Domain {
    // MARK: Lifecycle

    public init(_ name: String, domain: Domain? = nil) {
        self.name = name
        self.parent = domain

        self.graphite = Node(name: name, kind: .domain, priority: .child)

        if let domain {
            forward(from: eventCreated, to: domain.eventCreated)
            forward(from: storeCreated, to: domain.storeCreated)
            forward(from: domainCreated, to: domain.domainCreated)
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
