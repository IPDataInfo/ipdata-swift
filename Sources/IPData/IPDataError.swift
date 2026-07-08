import Foundation

/// The single error type thrown by ``IPDataClient`` for any non-2xx HTTP
/// response, or when the response body fails to decode.
public struct IPDataError: Error, LocalizedError, Sendable {
    /// HTTP status code of the failed response.
    public let status: Int
    /// Human-readable message. Parsed from `{"error": "..."}` when present,
    /// otherwise the raw response body (or a decode failure description).
    public let message: String

    public init(status: Int, message: String) {
        self.status = status
        self.message = message
    }

    public var errorDescription: String? {
        "ipdata: HTTP \(status): \(message)"
    }
}

/// Internal helper: extracts the `error` field from a JSON error body, or
/// falls back to the raw body as text.
enum IPDataErrorParser {
    private struct ErrorBody: Decodable {
        let error: String?
    }

    static func message(from data: Data) -> String {
        if let body = try? JSONDecoder().decode(ErrorBody.self, from: data),
           let message = body.error, !message.isEmpty {
            return message
        }
        return String(data: data, encoding: .utf8) ?? ""
    }
}
