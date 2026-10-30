# Todo
TodoList







## Project flow

```text
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
```
# To-Do Application – iOS & Azure Cloud Backend

A cloud-connected To-Do application developed collaboratively by **Group 6 Participants**. The project combines a native iOS application built with SwiftUI and a Java-based REST API deployed using Microsoft Azure Functions, with Azure SQL Database for persistent data storage.

The application enables users to create, view, update, delete, prioritize, and manage tasks through an intuitive mobile interface connected to a cloud-hosted backend.

## 1. Project Overview

This project demonstrates the development and integration of a full-stack mobile application using native iOS technologies, RESTful API communication, cloud services, and relational database integration.

The solution consists of two main components:

- **iOS Frontend:** A native iOS application developed using Swift and SwiftUI.
- **Cloud Backend:** A Java-based REST API deployed through Azure Functions and connected to Azure SQL Database.

### Repository Structure

The project components are maintained in separate Git branches within the same repository.

| Component       | Branch      | Source Code                                                                           |
| --------------- | ----------- | ------------------------------------------------------------------------------------- |
| iOS Application | `ios-cloud` | [View iOS Source Code](https://github.com/shamimrehana85/Todo/tree/ios-cloud/TodoApp) |
| Backend API     | `backend`   | [View Backend Source Code](https://github.com/shamimrehana85/Todo/tree/backend)       |

## 2. Key Features

### Task Management

- Create new tasks.
- Retrieve and display tasks.
- Edit existing tasks.
- Delete tasks.
- Mark tasks as completed.
- Assign task priorities: Low, Medium, and High.
- Add optional due dates.

### User Interface

- Native iOS interface developed using SwiftUI.
- Task list presentation.
- Loading-state handling.
- Empty-state presentation.
- Error-state handling.
- Pull-to-refresh functionality.
- Task management through an organized interface.

### Cloud Integration

- RESTful communication between the iOS application and backend.
- Cloud-hosted API using Azure Functions.
- Persistent task storage using Azure SQL Database.
- JSON-based data exchange.

## 3. Technology Stack

| Layer                 | Technologies                           |
| --------------------- | -------------------------------------- |
| Mobile Development    | Swift, SwiftUI                         |
| iOS Architecture      | MVVM                                   |
| State Management      | Swift Observation (`@Observable`)      |
| Networking            | URLSession, async/await                |
| Data Serialization    | Codable, JSON                          |
| Backend               | Java 21, Azure Functions v4            |
| API Architecture      | REST                                   |
| Database              | Azure SQL Database                     |
| Database Connectivity | JDBC, Microsoft SQL Server JDBC Driver |
| Build Management      | Maven                                  |
| Cloud Platform        | Microsoft Azure                        |
| Testing Dependencies  | JUnit 5, Mockito                       |

## 4. System Architecture

The application follows a client-server architecture. The iOS application communicates with the backend through HTTP requests. Azure Functions processes the requests and communicates with Azure SQL Database for data persistence.

```mermaid
```

### Application Workflow

1. The user interacts with the SwiftUI interface.
2. The ViewModel processes the requested operation.
3. The service layer sends an HTTP request to the backend.
4. Azure Functions receives and processes the request.
5. The backend communicates with Azure SQL Database.
6. The API returns a JSON response.
7. The iOS application updates its interface using the returned data.

## 5. iOS Implementation

### 5.1 SwiftUI Architecture

The iOS application uses the Model-View-ViewModel (MVVM) architectural pattern to separate the user interface, application state, data models, and networking responsibilities.

This separation improves maintainability, testability, and the organization of application logic.

### 5.2 Main Application Components

| Component           | Responsibility                                 |
| ------------------- | ---------------------------------------------- |
| `TodoCloudView`     | Displays and manages the task interface.       |
| `TodoListViewModel` | Manages application state and task operations. |
| `TodoItem`          | Represents the task data model.                |
| `TodoService`       | Defines the task service interface.            |
| `APITodoService`    | Handles communication with the cloud API.      |
| `TodoAppApp`        | Application entry point.                       |

### 5.3 State Management

The application uses Swift Observation through `@Observable` to manage ViewModel state.

The ViewModel coordinates task data and application state, allowing the SwiftUI interface to respond to changes.

This approach separates presentation logic from networking and task-management responsibilities.

### 5.4 Networking and Asynchronous Operations

The application uses:

- `URLSession` for HTTP communication.
- Swift concurrency with `async/await` for asynchronous operations.
- `Codable` for JSON encoding and decoding.
- A service abstraction to separate API communication from the user interface.

### 5.5 Loading, Empty, and Error States

The application includes user-interface handling for different application states:

- **Loading:** Provides feedback while task data is being retrieved.
- **Empty:** Presents an appropriate state when no tasks are available.
- **Error:** Provides feedback when an operation encounters an error.
- **Refresh:** Allows the task list to be refreshed.

### 5.6 UIKit Integration

\<badge color="warning">In progress\</badge>

The current implementation primarily uses SwiftUI for the native iOS interface.

UIKit integration is part of the team's ongoing development work and will be documented here once implemented and tested.

### 5.7 Accessibility

Accessibility considerations form part of the iOS implementation.

Accessibility support, including VoiceOver labels, control descriptions, Dynamic Type compatibility, and appropriate accessibility identifiers, should be documented as these features are implemented and verified.

## 6. Azure Integration

### 6.1 Azure Services

The backend uses Microsoft Azure services to provide cloud-based API functionality and persistent data storage.

| Azure Component            | Purpose                                              |
| -------------------------- | ---------------------------------------------------- |
| Azure Functions            | Hosts the backend API and processes requests.        |
| Azure SQL Database         | Stores task information persistently.                |
| Azure Cloud Infrastructure | Provides the deployment environment for the backend. |

### 6.2 Backend Responsibilities

The Java backend is responsible for:

- Receiving and processing API requests.
- Retrieving task information.
- Creating new tasks.
- Updating existing tasks.
- Deleting tasks.
- Communicating with Azure SQL Database.
- Returning structured JSON responses.

### 6.3 REST API Design

The API follows a resource-oriented approach using HTTP methods to perform task-management operations.

**Base API URL**

```text
https://func-todo-group6-arbtcmcre0dcduh7.canadaeast-01.azurewebsites.net/api/todos
```

| HTTP Method | Endpoint          | Description              |
| ----------- | ----------------- | ------------------------ |
| GET         | `/api/todos`      | Retrieve all tasks.      |
| POST        | `/api/todos`      | Create a new task.       |
| PUT         | `/api/todos/{id}` | Update an existing task. |
| DELETE      | `/api/todos/{id}` | Delete a task.           |

### 6.4 Data Persistence

Azure SQL Database provides persistent storage for task information.

The Java backend connects to the database using JDBC and the Microsoft SQL Server JDBC Driver.

This allows task information to be managed centrally rather than relying exclusively on temporary application state.

### 6.5 Security and Configuration

Security and configuration are important considerations in a cloud-connected application.

The following practices should be followed:

- Keep database credentials and sensitive configuration outside source control.
- Use environment-specific configuration for local development and cloud deployment.
- Avoid embedding database credentials in the iOS application.
- Use secure HTTPS communication for API requests.
- Configure and document the Azure Function authorization method.
- Apply appropriate database access permissions.

**Authentication and authorization:** The actual API authorization mechanism must be documented according to the deployed backend configuration. Do not assume that an endpoint is protected simply because it is hosted on Azure.

## 7. Quality and Reliability

### 7.1 Error Handling

The iOS application provides error-state handling for operations that cannot be completed successfully.

The service layer separates API communication from the user interface, while the ViewModel manages the application state presented to the user.

### 7.2 Testing

The backend project includes JUnit 5 and Mockito testing dependencies.

Testing should cover relevant application and backend functionality, including:

- Task creation.
- Task retrieval.
- Task updates.
- Task deletion.
- API response handling.
- Error scenarios.

Actual test cases, execution commands, and results should be added once verified.

### 7.3 Logging and Monitoring

Logging and monitoring are important for identifying application errors and backend issues.

The Azure environment can be used to monitor backend execution and diagnose failures. Any implemented logging mechanisms and monitoring configuration should be documented with the deployment details.

### 7.4 Performance Considerations

The application uses asynchronous networking with `async/await`, allowing network operations to be performed without unnecessarily blocking the user interface.

The service layer also separates network communication from presentation logic.

### 7.5 Offline Strategy

The application communicates with a cloud-hosted backend to retrieve and manage task information.

Offline persistence, automatic synchronization, and conflict resolution should not be considered implemented unless they are explicitly supported by the application.

## 8. Database Architecture

The backend uses Azure SQL Database for persistent task storage.

The Java backend communicates with the database through JDBC and the Microsoft SQL Server JDBC Driver.

This architecture separates the mobile application from the database layer and allows the backend to manage data access.

## 9. Getting Started

### 9.1 Prerequisites

**iOS Development**

- macOS
- Xcode
- Swift development environment
- iOS Simulator or compatible iOS device

**Backend Development**

- Java Development Kit (JDK) 21
- Apache Maven
- Azure Functions Core Tools
- Azure SQL Database access
- Appropriate database connection configuration

### 9.2 Running the iOS Application

1. Clone the repository:

   ```bash
   git clone https://github.com/shamimrehana85/Todo.git
   ```

2. Switch to the iOS branch:

   ```bash
   git checkout ios-cloud
   ```

3. Open the `TodoApp` project in Xcode.

4. Confirm the API endpoint configuration in the service layer.

5. Select an iOS Simulator or compatible device.

6. Build and run the application.

### 9.3 Running the Backend

1. Clone the repository:

   ```bash
   git clone https://github.com/shamimrehana85/Todo.git
   ```

2. Switch to the backend branch:

   ```bash
   git checkout backend
   ```

3. Open the backend project in a Java-compatible IDE.

4. Configure the required Azure Functions and database settings.

5. Build the project using Maven:

   ```bash
   mvn clean package
   ```

6. Run the Azure Functions project locally using Azure Functions Core Tools and the project's configuration.

**Configuration note:** The exact environment variable names, local settings, and database connection instructions should follow the backend implementation. Never publish database passwords, connection secrets, or Azure credentials in this README.

## 10. Deployment and Operational Runbook

The backend is designed to run as an Azure Functions application connected to Azure SQL Database.

A deployment runbook should cover:

1. Confirming the Java and Maven environment.
2. Verifying Azure Function App configuration.
3. Confirming database connectivity.
4. Configuring required environment variables and secrets.
5. Building the backend package.
6. Deploying the application to Azure.
7. Verifying the API endpoints.
8. Checking application logs for errors.

The deployed API endpoint is documented in Section 6.3.

## 11. Current Development Status

| Feature                                 | Status           |
| --------------------------------------- | ---------------- |
| SwiftUI user interface                  | Implemented      |
| MVVM architecture                       | Implemented      |
| State management                        | Implemented      |
| Cloud API integration                   | Implemented      |
| Azure Functions backend                 | Implemented      |
| Azure SQL Database integration          | Implemented      |
| Task CRUD operations                    | Implemented      |
| Loading and error states                | Implemented      |
| UIKit integration                       | In progress      |
| Additional accessibility verification   | To be documented |
| Automated test results                  | To be documented |
| Offline persistence and synchronization | Not claimed      |

## 12. Future Enhancements

Potential areas for further development include:

- UIKit integration.
- Expanded accessibility support.
- Automated unit and integration test coverage.
- Enhanced logging and monitoring.
- Improved offline functionality.
- User authentication and authorization.
- Task search, filtering, and sorting.
- Notifications and due-date reminders.

## 13. Project Team

**Group 6 Participants**

Collaborative project demonstrating native iOS development, backend API implementation, Azure cloud integration, and relational database connectivity.

## 14. Project Links

- [iOS Frontend – GitHub](https://github.com/shamimrehana85/Todo/tree/ios-cloud/TodoApp)
- [Backend – GitHub](https://github.com/shamimrehana85/Todo/tree/backend)

---

*Developed as a collaborative Group 6 project.*

