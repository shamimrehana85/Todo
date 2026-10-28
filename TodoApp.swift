//
//  TodoApp.swift
//  Todo
//
//  Created by participant on 2026-10-27.
//

import SwiftUI
import SwiftData
@main
struct TodoApp: App {
    var body: some Scene {
        WindowGroup {
            TodoListview()
                .modelContainer(for: TodoItem.self)
        }
    }
}
