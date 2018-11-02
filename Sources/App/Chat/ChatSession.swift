import Foundation
import Vapor

final class ChatSession: Hashable {
    private let socket: WebSocket
    var identity: ChatIdentity

    init(socket: WebSocket) {
        self.socket = socket
        self.identity = ChatIdentity(id: UUID())
    }

    func send(_ event: ChatOutgoingEvent) {
        guard let text = event.jsonString else {
            // TODO: log encoding failure
            return
        }

        socket.send(text: text)
    }

    var hashValue: Int {
        return identity.id.hashValue
    }

    static func == (lhs: ChatSession, rhs: ChatSession) -> Bool {
        return lhs.identity.id == rhs.identity.id
    }
}
