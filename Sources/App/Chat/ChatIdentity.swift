import Foundation

private let defaultName = "Anonymous"
private let defaultAvatar = "https://www.gravatar.com/avatar/00000000000000000000000000000000"

struct ChatIdentity: Codable {
    static let system = ChatIdentity(
        id: UUID(),
        name: "System",
        avatar: "https://avatars3.githubusercontent.com/u/17364220?v=3&s=200")

    let id: UUID
    var name: String?
    var avatar: String

    init(id: UUID, name: String? = nil, avatar: String? = nil) {
        self.id = id
        self.name = name
        self.avatar = avatar ?? defaultAvatar
    }
}
