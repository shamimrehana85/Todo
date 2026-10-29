# Todo
TodoList








## Project flow

┌──────────────────────────────────────┐
│ FRONT END: the iOS app               │
│ Screens (SwiftUI) → ViewModel →      │
│ TodoService (URLSession)             │
│ Runs on the user's phone             │
└──────────────────┬───────────────────┘
                   │  HTTPS request: POST /api/todos
                   │  body (JSON): {"title":"Buy groceries"}
                   ▼
┌──────────────────────────────────────┐
│ BACK END: Azure Function App         │
│ func-todo-group6, written in Java    │
│ CreateTodo: checks input, runs SQL   │
│ Runs in Azure, always on             │
└──────────────────┬───────────────────┘
                   │  JDBC: INSERT INTO dbo.Todos ...
                   │  (login comes from SQL_CONNECTION_STRING)
                   ▼
┌──────────────────────────────────────┐
│ DATABASE: Azure SQL (tododb)         │
│ Table dbo.Todos                      │
│ Id | Title | IsDone | Priority | ...  │
│ The only place data is stored        │
└──────────────────┬───────────────────┘
                   │  the new row comes back
                   ▼
  Back end turns the row into JSON → replies "201 Created"
  → front end adds it to the screen
