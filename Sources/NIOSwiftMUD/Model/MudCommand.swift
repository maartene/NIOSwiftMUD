struct MudResponse {
    let session: Session
    let message: String
}

protocol MudCommand {
    static var token: String { get }
    static var expectedArgumentCount: Int { get }
    static var requiresLogin: Bool { get }

    var session: Session { get }

    static func create(_ arguments: [String], session: Session) -> Self?
    func execute(in world: World) async -> [MudResponse]
}

extension MudCommand {
    var requiresLogin: Bool {
        Self.requiresLogin
    }

    var couldNotFindPlayerMessage: String {
        "Could not find player with id \(String(describing: session.playerID))."
    }
}
