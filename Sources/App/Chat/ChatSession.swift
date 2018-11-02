import Foundation
import Vapor

final class ChatSession {
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
}
