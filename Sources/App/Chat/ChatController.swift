import Vapor
import Dispatch

final class ChatController: Service {
    private let queue = DispatchQueue(label: "chat_queue", attributes: .concurrent)
    private var sessions: [UUID: ChatSession] = [:]

    // MARK: - Connection handler (entry point)
    func onUpgrade(socket: WebSocket, request: Request) {
        let newSession = ChatSession(socket: socket)
        let uuid = newSession.identity.id

        socket.eventLoop.scheduleRepeatedTask(initialDelay: .seconds(15), delay: .seconds(30)) { task -> Void in
            guard !socket.isClosed else {
                task.cancel()
                return
            }

            socket.send(raw: UUID().uuidString, opcode: .ping)
        }
        
        socket.onClose.whenSuccess {
            self.writeLocked {
                guard let finalSession = self.sessions.removeValue(forKey: uuid) else {
                    return
                }
                
                guard finalSession.identity.name != nil else {
                    // Users are not notified when an anonymous user disconnects.
                    return
                }
                
                self.multicast(.disconnect(finalSession.identity), to: self.sessions)
            }
        }

        socket.onText { _, text in self.dispatch(session: newSession, text: text) }

        writeLocked {
            newSession.send(.notice("Welcome back! Use the `/ident` command to select your username."))
            self.sessions[uuid] = newSession
        }
    }

    // MARK: - Incoming message handling
    private func dispatch(session: ChatSession, text: String) {
        guard text.starts(with: "/") else {
            // Not a command, broadcast as text message
            dispatchMessage(text, by: session)
            return
        }

        let parts = text.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)

        guard let command = parts.first?.lowercased() else {
            return
        }

        switch command {
        case "/ident":
            guard parts.count == 2 else {
                session.send(.error("Oops! Invalid number of arguments.  \nSyntax:  \n`/ident username`"))
                return
            }

            updateIdentity(of: session, to: String(parts[1]))
        case "/roster":
            session.send(.error("Oops! The Roster is not yet implemented"))
        default:
            session.send(.error("Oops! Invalid command: `\(command)`"))
        }
    }

    private func dispatchMessage(_ text: String, by session: ChatSession) {
        readLocked {
            guard session.identity.name != nil else {
                session.send(.error("Oops! You need to select a username before joining the conversation.  \nTry using the `/ident` command to select a unique username."))
                return
            }

            let message = ChatMessage(sender: session.identity, text: text)
            self.multicast(.message(message), to: self.sessions, excluding: session)
        }
    }

    private func updateIdentity(of session: ChatSession, to name: String) {
        let reserved = ["admin", "root", "anonymous", "system"]
        let alphanum = CharacterSet.alphanumerics

        guard !name.isEmpty else {
            session.send(.error("Oops! The new name cannot be empty."))
            return
        }

        guard name.rangeOfCharacter(from: alphanum.inverted) == nil else {
            session.send(.error("Oops! Try again with letters and numbers only."))
            return
        }
        
        guard !reserved.contains(name.lowercased()) else {
            session.send(.error("Oops! The name '\(name)' is reserved. Try again with a different name."))
            return
        }

        writeLocked {
            let sameName = self.sessions.values.first(where: { $0.identity.name?.lowercased() == name.lowercased() })

            guard sameName == nil || sameName?.identity.id == session.identity.id else {
                session.send(.error("The name '\(name)' is already in use.  \nTry again with a different name."))
                return
            }

            if let oldName = session.identity.name {
                session.identity.name = name
                session.send(.notice("You are now seen as '\(name)'."))
                self.multicast(.notice("'\(oldName)' is now '\(name)'"), to: self.sessions, excluding: session)
            } else {
                session.identity.name = name
                session.send(.notice("You are now seen as '\(name)'. Welcome!"))
                self.multicast(.connect(session.identity), to: self.sessions, excluding: session)
            }
        }
    }

    // MARK: - Outgoing message utilities
    private func multicast(_ event: ChatOutgoingEvent, to sessions: [UUID: ChatSession], excluding sender: ChatSession) {
        let otherSessions = sessions.filter { $0.key != sender.identity.id }
        multicast(event, to: otherSessions)
    }

    private func multicast(_ event: ChatOutgoingEvent, to sessions: [UUID: ChatSession]) {
        sessions.values.forEach { $0.send(event) }
    }

    // MARK: - Thread safe access to the session list
    private func readLocked(_ fn: () -> ()) {
        queue.sync {
            fn()
        }
    }
    
    private func writeLocked(_ fn: @escaping () -> ()) {
        queue.async(flags: .barrier) {
            fn()
        }
    }
}
