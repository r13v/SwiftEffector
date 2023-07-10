class Domain {
    // MARK: Lifecycle

    init(name: String, parent: Domain?) {
        self.name = name
        self.parent = parent

        self.graphite = Node(name: name, kind: .domain, priority: .child)
    }

    // MARK: Public

    public var graphite: Node
    public let name: String
    public var onCreateEvent: ((_ event: AnyEvent) -> Subscription)?
    public var onCreateStore: ((_ store: Store<Any>) -> Subscription)?
    public var onCreateEffect: ((_ effect: Effect<Any, Any, Error>) -> Subscription)?
    public var onCreateDomain: ((_ domain: Domain) -> Subscription)?

    public let parent: Domain?

    public var kind: String { "domain" }

    // MARK: Internal

    let events = [AnyEvent]()
}
