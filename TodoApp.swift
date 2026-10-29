//
//  TodoApp.swift
//  Todo
//
//  Created by participant on 2026-10-27.
//

import SwiftUI
import SwiftData // For environment
import UserNotifications // For Notifications
@main
struct TodoApp: App {
    // Initialize notification permissions when the app starts
    init(){
        requestNotificationPermission()
    }
    var body: some Scene {
        WindowGroup {
            TodoListview()
                .modelContainer(for: TodoItem.self)
        }
    }
    // Func to ask the user for permission'
    func requestNotificationPermission(){
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) {granted, error in
            if granted {
                print("Notofications Permission Granted!")
            }else if let error = error {
                print("Error Getting Permission: \(error.localizedDescription)")
            }
        }
    }
}
