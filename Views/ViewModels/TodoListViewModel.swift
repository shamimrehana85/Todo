import Foundation
import Observation

@Observable
final class TodoListViewModel {
    private(set) var todos: [TodoItem] = []
    private(set) var isLoading = false
    var errorMessage: String?

    private let service: TodoService

    // The service is "injected": the real one by default, a fake in tests
    init(service: TodoService = APITodoService()) {
        self.service = service
    }

    func load() async {
        isLoading = true
        do {
            todos = try await service.fetchTodos()
            errorMessage = nil
        } catch {
            // keep the old list on screen; just show the problem
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func add(title: String, priority: Priority, dueDate: Date?) async {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        do {
            _ = try await service.create(
                NewTodo(title: trimmed, priority: priority, dueDate: dueDate))
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggle(_ todo: TodoItem) async {
        await update(todo.id, TodoUpdate(isDone: !todo.isDone))
    }

    func update(_ id: UUID, _ changes: TodoUpdate) async {
        do {
            _ = try await service.update(id: id, changes)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(at offsets: IndexSet) async {
        let doomed = offsets.map { todos[$0] }
        do {
            for todo in doomed {
                try await service.delete(id: todo.id)
            }
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
