import SwiftUI

struct ContentView: View {
    @State private var status = "Testing the API…"

    var body: some View {
        Text(status)
            .multilineTextAlignment(.center)
            .padding()
            .task {
                do {
                    let service = APITodoService()
                    let created = try await service.create(
                        NewTodo(title: "From iOS", priority: .high,
                                dueDate: Date().addingTimeInterval(86_400)))
                    let all = try await service.fetchTodos()
                    try await service.delete(id: created.id)
                    status = "Round trip OK Created “\(created.title)”, the server held \(all.count) todo(s), then I deleted it."
                } catch {
                    status = "Error: \(error.localizedDescription)"
                }
            }
    }
}

#Preview {
    ContentView()
}
