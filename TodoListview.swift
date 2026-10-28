//
//  TodoListview.swift
//  Todo
//
//  Created by participant on 2026-10-27.
//

import Foundation
import SwiftUI
import SwiftData

struct TodoListview: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \TodoItem.createAt) private var todos: [TodoItem]
    @State private var newTitle = ""
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(todos) { todo in
                    HStack {
                        Button {
                            todo.isDone.toggle()
                        } label: {
                            Image(systemName: todo.isDone ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(todo.isDone ? .green : .secondary)
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                        
                        Text(todo.title)
                            .strikethrough(todo.isDone)
                            .foregroundStyle(todo.isDone ? .secondary : .primary)
                    }
                }
                .onDelete { offsets in
                    for index in offsets {
                        context.delete(todos[index])
                    }
                }
            }
            .overlay {
                if todos.isEmpty {
                    ContentUnavailableView(
                        "No todos yet",
                        systemImage: "checklist",
                        description: Text("Add your first task below")
                    )
                }
            }
            .navigationTitle("Todo - v1 (SwiftData)")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                HStack {
                    TextField("New todo", text: $newTitle)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Add") {
                        let trimmedTitle = newTitle.trimmingCharacters(in: .whitespaces)
                        guard !trimmedTitle.isEmpty else { return }
                        
                        context.insert(TodoItem(title: trimmedTitle))
                        newTitle = ""
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(.bar)
            }
        }
    }
}

#Preview {
    TodoListview()
        .modelContainer(for: TodoItem.self, inMemory: true)
}
