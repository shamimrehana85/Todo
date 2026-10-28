//
//  TodoItem.swift
//  Todo
//
//  Created by participant on 2026-10-27.
//

import Foundation
import SwiftData
@Model
final class TodoItem {
    var title: String
    var isDone: Bool
    var createAt: Date
    
    init(title: String) {
        self.title = title
        self.isDone = false
        self.createAt = .now
    }
}
