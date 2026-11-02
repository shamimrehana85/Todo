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

import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.Base64;
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
        String sql = "SELECT Id, Title, IsDone, CreatedAt, Priority, DueDate, Description FROM dbo.Todos ORDER BY CreatedAt";
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
        String priority = stringField(body, "priority");
        String dueDate = stringField(body, "dueDate");
        String description = stringField(body, "description");
        String clientId = stringField(body, "id");   // optional: the app may choose the id
        priority = normalizePriority(priority);
        if (priority != null && !isValidPriority(priority)) {
            return reply(request, HttpStatus.BAD_REQUEST,
                    "{\"error\":\"priority must be Low, Medium or High\"}");
        }
        String sql = "INSERT INTO dbo.Todos (Id, Title, Priority, DueDate, Description) "
                + "OUTPUT inserted.Id, inserted.Title, inserted.IsDone, inserted.CreatedAt, "
                + "inserted.Priority, inserted.DueDate, inserted.Description "
                + "VALUES (COALESCE(TRY_CONVERT(UNIQUEIDENTIFIER, ?), NEWID()), ?, "
                + "COALESCE(?, 'Medium'), TRY_CONVERT(DATETIMEOFFSET, ?), COALESCE(?, ''))";
        try (Connection db = connect();
        PreparedStatement statement = db.prepareStatement(sql)) {
            statement.setString(1, clientId);
            statement.setString(2, title);
            statement.setString(3, priority);
            statement.setString(4, dueDate);
            statement.setString(5, description);
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
        String priority = stringField(body, "priority");
        String dueDate = stringField(body, "dueDate");
        String description = stringField(body, "description");
        priority = normalizePriority(priority);
        if (priority != null && !isValidPriority(priority)) {
            return reply(request, HttpStatus.BAD_REQUEST,
                    "{\"error\":\"priority must be Low, Medium or High\"}");
        }
        String sql = "UPDATE dbo.Todos "
                + "SET Title = COALESCE(?, Title), IsDone = COALESCE(?, IsDone), "
                + "Priority = COALESCE(?, Priority), "
                + "DueDate = COALESCE(TRY_CONVERT(DATETIMEOFFSET, ?), DueDate), "
                + "Description = COALESCE(?, Description) "
                + "OUTPUT inserted.Id, inserted.Title, inserted.IsDone, inserted.CreatedAt, "
                + "inserted.Priority, inserted.DueDate, inserted.Description "
                + "WHERE Id = ?";
        try (Connection db = connect();
        PreparedStatement statement = db.prepareStatement(sql)) {
            statement.setString(1, title);
            if (isDone == null) {
                statement.setNull(2, Types.BIT);
            } else {
                statement.setBoolean(2, isDone);
            }
            statement.setString(3, priority);
            statement.setString(4, dueDate);
            statement.setString(5, description);
            statement.setString(6, id);
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

    // ---- POST /api/scan ---------------------------------------------
    // Receives {"imageBase64":"..."}, asks Azure AI Vision to read the text in the
    // photo, and answers {"lines":["Buy milk","Call Sam", ...]}.
    // The Vision key lives in app settings (VISION_ENDPOINT, VISION_KEY), never in the app.

    @FunctionName("ScanTodos")
    public HttpResponseMessage scanTodos(
            @HttpTrigger(name = "req", methods = {HttpMethod.POST},
            authLevel = AuthorizationLevel.ANONYMOUS, route = "scan")
            HttpRequestMessage<Optional<String>> request,
            final ExecutionContext context) {
        String body = request.getBody().orElse("");
        String imageBase64 = stringField(body, "imageBase64");
        if (imageBase64 == null || imageBase64.isBlank()) {
            return reply(request, HttpStatus.BAD_REQUEST,
                    "{\"error\":\"imageBase64 is required\"}");
        }

        String endpoint = System.getenv("VISION_ENDPOINT");
        String key = System.getenv("VISION_KEY");
        if (endpoint == null || endpoint.isBlank() || key == null || key.isBlank()) {
            return reply(request, HttpStatus.INTERNAL_SERVER_ERROR,
                    "{\"error\":\"AI Vision is not configured on the server\"}");
        }

        try {
            byte[] image = Base64.getDecoder().decode(imageBase64);
            String url = endpoint.replaceAll("/+$", "")
                    + "/computervision/imageanalysis:analyze?api-version=2024-02-01&features=read";

            HttpRequest visionRequest = HttpRequest.newBuilder(URI.create(url))
                    .header("Ocp-Apim-Subscription-Key", key)
                    .header("Content-Type", "application/octet-stream")
                    .POST(HttpRequest.BodyPublishers.ofByteArray(image))
                    .build();
            HttpResponse<String> visionResponse = HttpClient.newHttpClient()
                    .send(visionRequest, HttpResponse.BodyHandlers.ofString());

            if (visionResponse.statusCode() / 100 != 2) {
                context.getLogger().warning("Vision error: " + visionResponse.body());
                return reply(request, HttpStatus.INTERNAL_SERVER_ERROR,
                        "{\"error\":\"AI Vision replied with status "
                                + visionResponse.statusCode() + "\"}");
            }
            return reply(request, HttpStatus.OK, linesToJson(visionResponse.body()));
        } catch (IllegalArgumentException e) {
            return reply(request, HttpStatus.BAD_REQUEST,
                    "{\"error\":\"imageBase64 is not valid base64\"}");
        } catch (IOException | InterruptedException e) {
            return reply(request, HttpStatus.INTERNAL_SERVER_ERROR,
                    "{\"error\":\"could not reach AI Vision\"}");
        }
    }

    // ---- Helpers (same idea as the local TodoServer) ----------------

    private String rowToJson(ResultSet rows) throws SQLException {
        String created = iso(rows.getObject("CreatedAt", OffsetDateTime.class));
        String due = iso(rows.getObject("DueDate", OffsetDateTime.class));
        return "{\"id\":\"" + escape(rows.getString("Id").toLowerCase()) + "\","
                + "\"title\":\"" + escape(rows.getString("Title")) + "\","
                + "\"isDone\":" + rows.getBoolean("IsDone") + ","
                + "\"priority\":\"" + escape(rows.getString("Priority")) + "\","
                + "\"dueDate\":" + (due == null ? "null" : "\"" + due + "\"") + ","
                + "\"description\":\"" + escape(rows.getString("Description")) + "\","
                + "\"createdAt\":\"" + created + "\"}";
    }

    // ISO 8601 in UTC, e.g. 2026-11-01T17:00:00Z (what Swift's .iso8601 decoder reads)
    private static String iso(OffsetDateTime t) {
        if (t == null) return null;
        return t.withOffsetSameInstant(ZoneOffset.UTC)
                .truncatedTo(ChronoUnit.SECONDS)
                .format(DateTimeFormatter.ISO_OFFSET_DATE_TIME);
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

    // Pulls every recognised line of text out of the Vision response:
    // { "readResult": { "blocks": [ { "lines": [ { "text": "..." } ] } ] } }
    static String linesToJson(String visionJson) {
        JsonArray found = new JsonArray();
        JsonObject root = JsonParser.parseString(visionJson).getAsJsonObject();
        JsonObject readResult = root.getAsJsonObject("readResult");
        if (readResult != null && readResult.has("blocks")) {
            for (JsonElement block : readResult.getAsJsonArray("blocks")) {
                JsonObject blockObject = block.getAsJsonObject();
                if (!blockObject.has("lines")) continue;
                for (JsonElement line : blockObject.getAsJsonArray("lines")) {
                    String text = line.getAsJsonObject().get("text").getAsString().trim();
                    if (!text.isEmpty()) found.add(text);
                }
            }
        }
        JsonObject out = new JsonObject();
        out.add("lines", found);
        return out.toString();
    }

    // Accepts "high", "HIGH" or "High" and returns "High" (the wording the iOS app uses)
    static String normalizePriority(String p) {
        if (p == null || p.isBlank()) return null;
        String s = p.trim().toLowerCase();
        return Character.toUpperCase(s.charAt(0)) + s.substring(1);
    }

    static boolean isValidPriority(String p) {
        return p.equals("Low") || p.equals("Medium") || p.equals("High");
    }

    // Reads one text field from the request JSON (handles \n, quotes and unicode correctly)
    static String stringField(String json, String field) {
        try {
            JsonElement value = JsonParser.parseString(json).getAsJsonObject().get(field);
            if (value == null || value.isJsonNull()) return null;
            return value.getAsString();
        } catch (RuntimeException e) {
            return null;
        }
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
        StringBuilder out = new StringBuilder();
        for (char c : s.toCharArray()) {
            switch (c) {
                case '\\': out.append("\\\\"); break;
                case '"': out.append("\\\""); break;
                case '\n': out.append("\\n"); break;
                case '\r': out.append("\\r"); break;
                case '\t': out.append("\\t"); break;
                default:
                    if (c < 0x20) out.append(String.format("\\u%04x", (int) c));
                    else out.append(c);
            }
        }
        return out.toString();
    }
}