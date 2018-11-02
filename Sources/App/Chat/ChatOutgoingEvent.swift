import Foundation
import Core

private let jsonEncoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = JSONEncoder.DateEncodingStrategy.millisecondsSince1970
    return encoder
}()

enum ChatOutgoingEvent: Encodable {
    case connect(ChatIdentity)
    case disconnect(ChatIdentity)
    case message(ChatMessage)
    case identify(ChatIdentity)
    case notice(String)
    case error(String)

    func encode(to encoder: Encoder) throws {
        var kvc = encoder.container(keyedBy: String.self)

        switch self {
        case .connect(let identity):
            try kvc.encode("connect", forKey: "type")
            try kvc.encode(identity, forKey: "user")
        case .disconnect(let identity):
            try kvc.encode("disconnect", forKey: "type")
            try kvc.encode(identity, forKey: "user")
        case .message(let message):
            try kvc.encode("message", forKey: "type")
            try kvc.encode(message, forKey: "message")
        case .identify(let identity):
            try kvc.encode("ident", forKey: "type")
            try kvc.encode(identity, forKey: "user")
        case .notice(let message):
            try kvc.encode("notice", forKey: "type")
            try kvc.encode(message, forKey: "message")
        case .error(let error):
            try kvc.encode("error", forKey: "type")
            try kvc.encode(error, forKey: "message")
        }
    }
}

extension ChatOutgoingEvent {
    var jsonString: String? {
        guard let jsonData = try? jsonEncoder.encode(self) else {
            return nil
        }

        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }
    
        return jsonString
    }
}
