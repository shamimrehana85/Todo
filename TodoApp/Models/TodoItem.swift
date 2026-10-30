import Foundation

enum Priority: String, Codable, CaseIterable, Identifiable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    var id: String { rawValue }
}

// Matches the JSON your Azure Function returns
struct TodoItem: Codable, Identifiable, Equatable {
    let id: UUID
    var title: String
    var isDone: Bool
    var priority: Priority
    var dueDate: Date?
    let createdAt: Date
}

// What we SEND when creating a todo
struct NewTodo: Encodable {
    var title: String
    var priority: Priority = .medium
    var dueDate: Date?
}

// What we SEND when updating. Anything left nil is not sent,
// so the server keeps the old value (your COALESCE).
struct TodoUpdate: Encodable {
    var title: String?
    var isDone: Bool?
    var priority: Priority?
    var dueDate: Date?
}
