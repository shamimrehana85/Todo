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
    @State private var taskToEdit: TodoItem? = nil
    
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
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Trigger editing when tapping the row
                        taskToEdit = todo
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
                    if showDatePicker {
                        HStack {
                            Label("Due Date", systemImage: "calendar")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            DatePicker("", selection: $dueDate, displayedComponents: .date)
                                .labelsHidden()
                        }
                        .padding(.horizontal)
                    }
                    
                    HStack {
                        TextField("New todo", text: $newTitle)
                            .textFieldStyle(.roundedBorder)
                        
                        // Calendar Toggle Button
                        Button {
                            showDatePicker.toggle()
                        } label: {
                            Image(systemName: showDatePicker ? "calendar.badge.minus" : "calendar.badge.plus")
                                .font(.title3)
                                .foregroundStyle(showDatePicker ? .blue : .secondary)
                        }
                        .buttonStyle(.plain)
                        
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
                            showDatePicker = false
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                .background(.bar)
            }
            .sheet(item: $taskToEdit) { task in
                EditTaskView(task: task)
            }
        }
    }
}

struct EditTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var task: TodoItem
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Task Details") {
                    TextField("Title", text: $task.title)
                    
                    Picker("Priority", selection: $task.priority) {
                        Text("Low").tag("Low")
                        Text("Medium").tag("Medium")
                        Text("High").tag("High")
                    }
                    
                    // Due Date Toggle and Picker for existing tasks
                    Toggle("Set Due Date", isOn: Binding(
                        get: { task.dueDate != nil },
                        set: { isOn in
                            task.dueDate = isOn ? Date() : nil
                        }
                    ))
                    
                    if task.dueDate != nil {
                        DatePicker("Due Date", selection: Binding(
                            get: { task.dueDate ?? Date() },
                            set: { task.dueDate = $0 }
                        ), displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    TodoListview()
        .modelContainer(for: TodoItem.self, inMemory: true)
}
