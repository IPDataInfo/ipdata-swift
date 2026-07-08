import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Official Swift client for the ipdata.info IP geolocation, ASN, and
/// threat-intelligence API. See https://ipdata.info.
///
/// The client is an actor: all network calls are `async` and safe to invoke
/// concurrently from multiple tasks.
public actor IPDataClient {
    /// Free tier host: 50 req/min, no API key required.
    public static let defaultBaseURL = URL(string: "https://ipdata.info")!
    /// Paid tier host used automatically when an API key is supplied and no
    /// explicit `baseURL` is given.
    public static let proBaseURL = URL(string: "https://pro.ipdata.info")!

    private static let version = "0.1.0"
    private static let userAgent = "ipdata-swift/\(version)"

    private let apiKey: String?
    private let baseURL: URL
    private let timeout: TimeInterval
    private let session: URLSession

    /// Creates a client.
    ///
    /// - Parameters:
    ///   - apiKey: Sent as the `X-Api-Key` header when non-nil. Omit for
    ///     anonymous free-tier calls.
    ///   - baseURL: API host. Defaults to the free tier
    ///     (`https://ipdata.info`) unless `apiKey` is set, in which case it
    ///     defaults to the pro tier (`https://pro.ipdata.info`).
    ///   - timeout: Per-request timeout in seconds. Defaults to 10.
    ///   - session: Custom `URLSession` (e.g. for testing via a mocked
    ///     `URLProtocol`). Defaults to a session configured with `timeout`.
    public init(
        apiKey: String? = nil,
        baseURL: URL? = nil,
        timeout: TimeInterval = 10,
        session: URLSession? = nil
    ) {
        self.apiKey = apiKey
        self.timeout = timeout
        self.baseURL = baseURL ?? (apiKey != nil ? Self.proBaseURL : Self.defaultBaseURL)
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.timeoutIntervalForRequest = timeout
            self.session = URLSession(configuration: configuration)
        }
    }

    /// Returns the full geolocation record for `ip`. Pass an empty string
    /// (the default) to look up the caller's own IP via `/json/`.
    public func lookup(_ ip: String = "") async throws -> IPInfo {
        try await get("/json/\(pathEscape(ip))")
    }

    /// Returns the compact geo subset for `ip`.
    public func geo(_ ip: String) async throws -> GeoInfo {
        try await get("/api/v1/\(pathEscape(ip))/geo")
    }

    /// Returns the compact ASN subset for `ip`.
    public func asn(_ ip: String) async throws -> ASNBrief {
        try await get("/api/v1/\(pathEscape(ip))/asn")
    }

    /// Looks up many IPs at once. Requires a paid-tier API key; without one
    /// the API returns `403` with `{"error": "batch lookup requires a paid
    /// tier API key"}`, surfaced as ``IPDataError``.
    public func batch(_ ips: [String]) async throws -> [IPInfo] {
        let body = try JSONEncoder().encode(ips)
        return try await send(method: "POST", path: "/api/v1/batch", body: body)
    }

    /// Returns the detailed ASN record (prefixes, peering) as a raw JSON
    /// value. The shape is large and paginated; see the API contract docs.
    public func asnDetail(_ number: Int) async throws -> JSONValue {
        try await get("/api/v1/asn/\(number)")
    }

    /// Returns the ASN whois history as a raw JSON value.
    public func asnWhoisHistory(_ number: Int) async throws -> JSONValue {
        try await get("/api/v1/asn/\(number)/whois-history")
    }

    /// Returns the ASN change feed as a raw JSON value.
    public func asnChanges() async throws -> JSONValue {
        try await get("/api/v1/asn-changes")
    }

    /// Looks up a domain in the threat-intel store.
    public func threatDomain(_ domain: String) async throws -> ThreatMatch {
        try await get("/api/v1/threat/domain/\(pathEscape(domain))")
    }

    /// Looks up a file hash (md5/sha1/sha256).
    public func threatHash(_ hash: String) async throws -> ThreatMatch {
        try await get("/api/v1/threat/hash/\(pathEscape(hash))")
    }

    /// Looks up a URL. The server falls back to the URL's domain on a miss.
    public func threatURL(_ url: String) async throws -> ThreatMatch {
        var components = URLComponents()
        components.queryItems = [URLQueryItem(name: "u", value: url)]
        let query = components.percentEncodedQuery ?? ""
        return try await get("/api/v1/threat/url?\(query)")
    }

    // MARK: - Transport

    private func get<T: Decodable>(_ path: String) async throws -> T {
        try await send(method: "GET", path: path, body: nil)
    }

    private func send<T: Decodable>(method: String, path: String, body: Data?) async throws -> T {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw IPDataError(status: 0, message: "invalid request path: \(path)")
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = timeout
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let apiKey {
            request.setValue(apiKey, forHTTPHeaderField: "X-Api-Key")
        }
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw IPDataError(status: 0, message: "request failed: \(error.localizedDescription)")
        }

        guard let http = response as? HTTPURLResponse else {
            throw IPDataError(status: 0, message: "no HTTP response")
        }
        guard (200..<300).contains(http.statusCode) else {
            throw IPDataError(status: http.statusCode, message: IPDataErrorParser.message(from: data))
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw IPDataError(status: http.statusCode, message: "decode response: \(error.localizedDescription)")
        }
    }

    private func pathEscape(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? value
    }
}
