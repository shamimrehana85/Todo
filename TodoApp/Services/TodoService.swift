import Foundation

protocol TodoService {
    func fetchTodos() async throws -> [TodoItem]
    func create(_ todo: NewTodo) async throws -> TodoItem
    func update(id: UUID, _ changes: TodoUpdate) async throws -> TodoItem
    func delete(id: UUID) async throws
}

enum TodoServiceError: LocalizedError {
    case invalidResponse
    case server(status: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The server sent an unexpected response."
        case .server(let status, let message):
            return "Server error \(status): \(message)"
        }
    }
}

struct APITodoService: TodoService {
    private let baseURL = URL(string: "https://func-todo-group6-arbtcmcre0dcduh7.canadaeast-01.azurewebsites.net/api/todos")!
    private let session = URLSession.shared

    private var decoder: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601   // reads 2026-11-05T17:00:00Z
        return d
    }

    private var encoder: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }

    func fetchTodos() async throws -> [TodoItem] {
        let data = try await send(URLRequest(url: baseURL))
        return try decoder.decode([TodoItem].self, from: data)
    }

    func create(_ todo: NewTodo) async throws -> TodoItem {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(todo)
        let data = try await send(request)
        return try decoder.decode(TodoItem.self, from: data)
    }

    func update(id: UUID, _ changes: TodoUpdate) async throws -> TodoItem {
        var request = URLRequest(url: itemURL(id))
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(changes)
        let data = try await send(request)
        return try decoder.decode(TodoItem.self, from: data)
    }

    func delete(id: UUID) async throws {
        var request = URLRequest(url: itemURL(id))
        request.httpMethod = "DELETE"
        _ = try await send(request)
    }

    // MARK: - Helpers

    private func itemURL(_ id: UUID) -> URL {
        baseURL.appendingPathComponent(id.uuidString.lowercased())
    }

    // One place that sends a request and checks the status code
    private func send(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw TodoServiceError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? ""
            throw TodoServiceError.server(status: http.statusCode, message: message)
        }
        return data
    }
}
