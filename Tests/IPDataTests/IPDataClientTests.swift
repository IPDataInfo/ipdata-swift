import Testing
import Foundation
@testable import IPData

private func makeClient(apiKey: String? = nil) -> IPDataClient {
    IPDataClient(apiKey: apiKey, baseURL: URL(string: "https://mock.local"),
                 session: MockURLProtocol.makeSession())
}

/// `.serialized` because every test configures the same
/// `MockURLProtocol.requestHandler` global; running them concurrently (the
/// Swift Testing default) would race on that shared state.
@Suite(.serialized)
struct IPDataClientTests {
    @Test func lookupParsesResponse() async throws {
        let json = """
        {"ip":"8.8.8.8","success":true,"type":"IPv4",
         "country":"United States","country_code":"US","asn":15169,
         "security":{"tor":false,"proxy":false}}
        """.data(using: .utf8)!

        MockURLProtocol.requestHandler = { request in
            #expect(request.url?.path == "/json/8.8.8.8")
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200,
                httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
            return (response, json)
        }

        let info = try await makeClient().lookup("8.8.8.8")
        #expect(info.countryCode == "US")
        #expect(info.asn == 15169)
        #expect(info.security != nil)
    }

    @Test func errorResponseThrowsIPDataError() async {
        let body = #"{"error":"batch lookup requires a paid tier API key"}"#.data(using: .utf8)!
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 403,
                httpVersion: nil, headerFields: nil)!
            return (response, body)
        }

        do {
            _ = try await makeClient().batch(["8.8.8.8"])
            Issue.record("expected IPDataError to be thrown")
        } catch let apiError as IPDataError {
            #expect(apiError.status == 403)
            #expect(!apiError.message.isEmpty)
        } catch {
            Issue.record("unexpected error type: \(error)")
        }
    }

    @Test func apiKeySendsHeaderAndDefaultsToProHost() async throws {
        let json = #"{"ip":"1.1.1.1","success":true,"type":"IPv4"}"#.data(using: .utf8)!
        MockURLProtocol.requestHandler = { request in
            #expect(request.value(forHTTPHeaderField: "X-Api-Key") == "secret")
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200,
                httpVersion: nil, headerFields: nil)!
            return (response, json)
        }

        // Default base URL should switch to pro tier when apiKey is set.
        let client = IPDataClient(apiKey: "secret", session: MockURLProtocol.makeSession())
        let info = try await client.lookup("1.1.1.1")
        #expect(info.ip == "1.1.1.1")
    }

    @Test func noAPIKeyOmitsHeader() async throws {
        let json = #"{"ip":"1.1.1.1","success":true,"type":"IPv4"}"#.data(using: .utf8)!
        MockURLProtocol.requestHandler = { request in
            #expect(request.value(forHTTPHeaderField: "X-Api-Key") == nil)
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200,
                httpVersion: nil, headerFields: nil)!
            return (response, json)
        }
        _ = try await makeClient().lookup("1.1.1.1")
    }

    /// Hits the real free endpoint. Skipped unless IPDATA_LIVE is set.
    @Test(.enabled(if: ProcessInfo.processInfo.environment["IPDATA_LIVE"] != nil))
    func liveSmoke() async throws {
        let client = IPDataClient()
        let info = try await client.lookup("8.8.8.8")
        #expect(info.ip == "8.8.8.8")
        #expect(info.success == true)
    }
}
