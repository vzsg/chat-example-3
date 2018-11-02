import Foundation

struct ChatMessage: Codable {
    let sender: ChatIdentity
    let timestamp: Date
    let text: String

    init(sender: ChatIdentity, text: String) {
        self.sender = sender
        self.timestamp = Date()
        self.text = text
    }
}
