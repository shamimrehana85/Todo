package com.orderup.todo;

import com.microsoft.azure.functions.ExecutionContext;
import com.microsoft.azure.functions.HttpMethod;
import com.microsoft.azure.functions.HttpRequestMessage;
import com.microsoft.azure.functions.HttpResponseMessage;
import com.microsoft.azure.functions.HttpStatus;
import com.microsoft.azure.functions.annotation.AuthorizationLevel;
import com.microsoft.azure.functions.annotation.BindingName;
import com.microsoft.azure.functions.annotation.FunctionName;
import com.microsoft.azure.functions.annotation.HttpTrigger;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;
import java.util.Optional;

/**
 * The same four routes as the local TodoServer, now as Azure Functions.
 * Each function opens a JDBC connection to Azure SQL, runs one statement,
 * and answers with the exact same JSON shape the iOS app already speaks.
 *
 * The connection string comes from the Function App setting
 * SQL_CONNECTION_STRING — never hard-code credentials.
 */
public class TodoFunctions {

    private Connection connect() throws SQLException {
        String url = System.getenv("SQL_CONNECTION_STRING");
        return DriverManager.getConnection(url);
    }

    // ---- GET /api/todos ---------------------------------------------

    @FunctionName("GetTodos")
    public HttpResponseMessage getTodos(
            @HttpTrigger(name = "req", methods = {HttpMethod.GET},
            authLevel = AuthorizationLevel.ANONYMOUS, route = "todos")
            HttpRequestMessage<Optional<String>> request,
            final ExecutionContext context) {
        String sql = "SELECT Id, Title, IsDone, CreatedAt FROM dbo.Todos ORDER BY CreatedAt";
        try (Connection db = connect();
        Statement statement = db.createStatement();
        ResultSet rows = statement.executeQuery(sql)) {
            StringBuilder json = new StringBuilder("[");
            boolean first = true;
            while (rows.next()) {
                if (!first) json.append(",");
                first = false;
                json.append(rowToJson(rows));
            }
            json.append("]");
            return reply(request, HttpStatus.OK, json.toString());
        } catch (SQLException e) {
            return sqlError(request, e);
        }
    }

    // ---- POST /api/todos --------------------------------------------

    @FunctionName("CreateTodo")
    public HttpResponseMessage createTodo(
            @HttpTrigger(name = "req", methods = {HttpMethod.POST},
            authLevel = AuthorizationLevel.ANONYMOUS, route = "todos")
            HttpRequestMessage<Optional<String>> request,
            final ExecutionContext context) {
        String body = request.getBody().orElse("");
        String title = stringField(body, "title");
        if (title == null || title.isBlank()) {
            return reply(request, HttpStatus.BAD_REQUEST,
                    "{\"error\":\"title is required\"}");
        }
        String sql = "INSERT INTO dbo.Todos (Title) "
                + "OUTPUT inserted.Id, inserted.Title, inserted.IsDone, inserted.CreatedAt "
                + "VALUES (?)";
        try (Connection db = connect();
        PreparedStatement statement = db.prepareStatement(sql)) {
            statement.setString(1, title);
            try (ResultSet rows = statement.executeQuery()) {
                rows.next();
                return reply(request, HttpStatus.CREATED, rowToJson(rows));
            }
        } catch (SQLException e) {
            return sqlError(request, e);
        }
    }

    // ---- PUT /api/todos/{id} ----------------------------------------

    @FunctionName("UpdateTodo")
    public HttpResponseMessage updateTodo(
            @HttpTrigger(name = "req", methods = {HttpMethod.PUT},
            authLevel = AuthorizationLevel.ANONYMOUS, route = "todos/{id}")
            HttpRequestMessage<Optional<String>> request,
            @BindingName("id") String id,
            final ExecutionContext context) {
        String body = request.getBody().orElse("");
        String title = stringField(body, "title");
        Boolean isDone = boolField(body, "isDone");
        String sql = "UPDATE dbo.Todos "
                + "SET Title = COALESCE(?, Title), IsDone = COALESCE(?, IsDone) "
                + "OUTPUT inserted.Id, inserted.Title, inserted.IsDone, inserted.CreatedAt "
                + "WHERE Id = ?";
        try (Connection db = connect();
        PreparedStatement statement = db.prepareStatement(sql)) {
            statement.setString(1, title);
            if (isDone == null) {
                statement.setNull(2, Types.BIT);
            } else {
                statement.setBoolean(2, isDone);
            }
            statement.setString(3, id);
            try (ResultSet rows = statement.executeQuery()) {
                if (rows.next()) {
                    return reply(request, HttpStatus.OK, rowToJson(rows));
                }
                return reply(request, HttpStatus.NOT_FOUND,
                        "{\"error\":\"no todo with that id\"}");
            }
        } catch (SQLException e) {
            return sqlError(request, e);
        }
    }

    // ---- DELETE /api/todos/{id} -------------------------------------

    @FunctionName("DeleteTodo")
    public HttpResponseMessage deleteTodo(
            @HttpTrigger(name = "req", methods = {HttpMethod.DELETE},
            authLevel = AuthorizationLevel.ANONYMOUS, route = "todos/{id}")
            HttpRequestMessage<Optional<String>> request,
            @BindingName("id") String id,
            final ExecutionContext context) {
        try (Connection db = connect();
        PreparedStatement statement =
                db.prepareStatement("DELETE FROM dbo.Todos WHERE Id = ?")) {
            statement.setString(1, id);
            int removed = statement.executeUpdate();
            if (removed > 0) {
                return reply(request, HttpStatus.NO_CONTENT, "");
            }
            return reply(request, HttpStatus.NOT_FOUND,
                    "{\"error\":\"no todo with that id\"}");
        } catch (SQLException e) {
            return sqlError(request, e);
        }
    }

    // ---- Helpers (same idea as the local TodoServer) ----------------

    private String rowToJson(ResultSet rows) throws SQLException {
        return "{\"id\":\"" + escape(rows.getString("Id").toLowerCase()) + "\","
                + "\"title\":\"" + escape(rows.getString("Title")) + "\","
                + "\"isDone\":" + rows.getBoolean("IsDone") + ","
                + "\"createdAt\":\"" + escape(rows.getString("CreatedAt")) + "\"}";
    }

    private HttpResponseMessage reply(HttpRequestMessage<?> request,
            HttpStatus status, String body) {
        return request.createResponseBuilder(status)
                .header("Content-Type", "application/json")
                .body(body)
                .build();
    }

    private HttpResponseMessage sqlError(HttpRequestMessage<?> request, SQLException e) {
        return reply(request, HttpStatus.INTERNAL_SERVER_ERROR,
                "{\"error\":\"" + escape(e.getMessage()) + "\"}");
    }

    static String stringField(String json, String field) {
        int at = json.indexOf("\"" + field + "\"");
        if (at < 0) return null;
        int colon = json.indexOf(':', at);
        int open = json.indexOf('"', colon + 1);
        if (open < 0) return null;
        StringBuilder value = new StringBuilder();
        for (int i = open + 1; i < json.length(); i++) {
            char c = json.charAt(i);
            if (c == '\\' && i + 1 < json.length()) {
                value.append(json.charAt(++i));
            } else if (c == '"') {
                return value.toString();
            } else {
                value.append(c);
            }
        }
        return null;
    }

    static Boolean boolField(String json, String field) {
        int at = json.indexOf("\"" + field + "\"");
        if (at < 0) return null;
        int colon = json.indexOf(':', at);
        String rest = json.substring(colon + 1).trim();
        if (rest.startsWith("true")) return true;
        if (rest.startsWith("false")) return false;
        return null;
    }

    static String escape(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}