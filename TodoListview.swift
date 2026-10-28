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
    @State private var selectedPriority = "Medium"
    @State private var dueDate = Date()
    @State private var showDatePicker = false
    
    private func priorityColor(for priority: String) -> Color {
        switch priority {
        case "High": return .red
        case "Medium": return .orange
        case "Low": return .gray
        default: return .blue
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(todos) { todo in
                    HStack {
                        // Completion Checkbox
                        Button {
                            todo.isDone.toggle()
                        } label: {
                            Image(systemName: todo.isDone ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(todo.isDone ? .green : .secondary)
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            // Task Title
                            Text(todo.title)
                                .strikethrough(todo.isDone)
                                .foregroundStyle(todo.isDone ? .secondary : .primary)
                            
                            // Due Date
                            if let due = todo.dueDate {
                                Text(due, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        // Priority Badge
                        Text(todo.priority)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(priorityColor(for: todo.priority).opacity(0.2))
                            .foregroundStyle(priorityColor(for: todo.priority))
                            .clipShape(Capsule())
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
                VStack(spacing: 8) {
                    HStack {
                        TextField("New todo", text: $newTitle)
                            .textFieldStyle(.roundedBorder)
                        
                        Picker("Priority", selection: $selectedPriority) {
                            Text("Low").tag("Low")
                            Text("Med").tag("Medium")
                            Text("High").tag("High")
                        }
                        .pickerStyle(.menu)
                        
                        Button("Add") {
                            let trimmedTitle = newTitle.trimmingCharacters(in: .whitespaces)
                            guard !trimmedTitle.isEmpty else { return }
                            
                            let newItem = TodoItem(
                                title: trimmedTitle,
                                priority: selectedPriority,
                                dueDate: showDatePicker ? dueDate : nil
                            )
                            context.insert(newItem)
                            newTitle = ""
                        }
                        .buttonStyle(.borderedProminent)
                    }
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
