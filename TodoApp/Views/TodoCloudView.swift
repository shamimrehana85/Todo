import SwiftUI

struct TodoCloudView: View {
    @State private var vm = TodoListViewModel()

    @State private var newTitle = ""
    @State private var selectedPriority: Priority = .medium
    @State private var dueDate = Date()
    @State private var showDatePicker = false
    @State private var todoToEdit: TodoItem?

    var body: some View {
        NavigationStack {
            List {
                ForEach(vm.todos) { todo in
                    row(for: todo)
                }
                .onDelete { offsets in
                    Task { await vm.delete(at: offsets) }
                }
            }
            .overlay { emptyOrLoading }
            .navigationTitle("Todo — v2 (Cloud)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button {
                    Task { await vm.load() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .refreshable { await vm.load() }
            .task { await vm.load() }
            .safeAreaInset(edge: .bottom) { addBar }
            .sheet(item: $todoToEdit) { todo in
                EditTodoView(todo: todo) { changes in
                    Task { await vm.update(todo.id, changes) }
                }
            }
        }
    }

    // MARK: - One row

    private func row(for todo: TodoItem) -> some View {
        HStack {
            Button {
                Task { await vm.toggle(todo) }
            } label: {
                Image(systemName: todo.isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(todo.isDone ? .green : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(todo.title)
                    .strikethrough(todo.isDone)
                    .foregroundStyle(todo.isDone ? .secondary : .primary)
                if let due = todo.dueDate {
                    Text(due, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(todo.priority.rawValue)
                .font(.caption2)
                .fontWeight(.bold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(todo.priority.color.opacity(0.2))
                .foregroundStyle(todo.priority.color)
                .clipShape(Capsule())
        }
        .contentShape(Rectangle())
        .onTapGesture { todoToEdit = todo }
    }

    // MARK: - Loading / empty state

    @ViewBuilder
    private var emptyOrLoading: some View {
        if vm.isLoading && vm.todos.isEmpty {
            ProgressView("Loading todos…")
        } else if vm.todos.isEmpty && vm.errorMessage == nil {
            ContentUnavailableView("No todos yet",
                                   systemImage: "cloud",
                                   description: Text("Add a task — it is saved on the server."))
        }
    }

    // MARK: - Add bar (with the error banner)

    private var addBar: some View {
        VStack(spacing: 8) {
            if let message = vm.errorMessage {
                Label(message, systemImage: "wifi.exclamationmark")
                    .font(.footnote)
                    .foregroundStyle(.white)
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(.red, in: RoundedRectangle(cornerRadius: 8))
            }
            if showDatePicker {
                HStack {
                    Label("Due Date", systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    DatePicker("", selection: $dueDate, displayedComponents: .date)
                        .labelsHidden()
                }
            }
            HStack {
                TextField("New todo", text: $newTitle)
                    .textFieldStyle(.roundedBorder)

                Button {
                    showDatePicker.toggle()
                } label: {
                    Image(systemName: showDatePicker ? "calendar.badge.minus" : "calendar.badge.plus")
                        .font(.title3)
                        .foregroundStyle(showDatePicker ? .blue : .secondary)
                }
                .buttonStyle(.plain)

                Picker("Priority", selection: $selectedPriority) {
                    ForEach(Priority.allCases) { p in
                        Text(p.rawValue).tag(p)
                    }
                }
                .pickerStyle(.menu)

                Button("Add") { add() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(.bar)
    }

    private func add() {
        let title = newTitle
        let priority = selectedPriority
        let due = showDatePicker ? dueDate : nil
        newTitle = ""
        showDatePicker = false
        Task { await vm.add(title: title, priority: priority, dueDate: due) }
    }
}

// MARK: - Edit sheet

struct EditTodoView: View {
    @Environment(\.dismiss) private var dismiss
    let todo: TodoItem
    let onSave: (TodoUpdate) -> Void

    @State private var title: String
    @State private var priority: Priority
    @State private var hasDueDate: Bool
    @State private var dueDate: Date

    init(todo: TodoItem, onSave: @escaping (TodoUpdate) -> Void) {
        self.todo = todo
        self.onSave = onSave
        _title = State(initialValue: todo.title)
        _priority = State(initialValue: todo.priority)
        _hasDueDate = State(initialValue: todo.dueDate != nil)
        _dueDate = State(initialValue: todo.dueDate ?? Date())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task Details") {
                    TextField("Title", text: $title)
                    Picker("Priority", selection: $priority) {
                        ForEach(Priority.allCases) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                    Toggle("Set Due Date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate,
                                   displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSave(TodoUpdate(title: title,
                                          priority: priority,
                                          dueDate: hasDueDate ? dueDate : nil))
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

// MARK: - Priority colours

extension Priority {
    var color: Color {
        switch self {
        case .high: return .red
        case .medium: return .orange
        case .low: return .gray
        }
    }
}//
//  TodoCloudView.swift
//  TodoApp
//
//  Created by participant on 2026-10-30.
//

