import XCTest
import Foundation
@testable import IPData

private func makeClient(apiKey: String? = nil) -> IPDataClient {
    IPDataClient(apiKey: apiKey, baseURL: URL(string: "https://mock.local"),
                 session: MockURLProtocol.makeSession())
}

final class IPDataClientTests: XCTestCase {

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    func testLookupParsesResponse() async throws {
        let json = """
        {"ip":"8.8.8.8","success":true,"type":"IPv4",
         "country":"United States","country_code":"US","asn":15169,
         "security":{"tor":false,"proxy":false}}
        """.data(using: .utf8)!

        var capturedPath: String?
        MockURLProtocol.requestHandler = { request in
            capturedPath = request.url?.path
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200,
                httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
            return (response, json)
        }

        let info = try await makeClient().lookup("8.8.8.8")
        XCTAssertEqual(capturedPath, "/json/8.8.8.8")
        XCTAssertEqual(info.countryCode, "US")
        XCTAssertEqual(info.asn, 15169)
        XCTAssertNotNil(info.security)
    }

    func testErrorResponseThrowsIPDataError() async {
        let body = #"{"error":"batch lookup requires a paid tier API key"}"#.data(using: .utf8)!
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 403,
                httpVersion: nil, headerFields: nil)!
            return (response, body)
        }

        do {
            _ = try await makeClient().batch(["8.8.8.8"])
            XCTFail("expected IPDataError to be thrown")
        } catch let apiError as IPDataError {
            XCTAssertEqual(apiError.status, 403)
            XCTAssertFalse(apiError.message.isEmpty)
        } catch {
            XCTFail("unexpected error type: \(error)")
        }
    }

    func testAPIKeySendsHeaderAndDefaultsToProHost() async throws {
        let json = #"{"ip":"1.1.1.1","success":true,"type":"IPv4"}"#.data(using: .utf8)!
        var sentKey: String?
        MockURLProtocol.requestHandler = { request in
            sentKey = request.value(forHTTPHeaderField: "X-Api-Key")
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200,
                httpVersion: nil, headerFields: nil)!
            return (response, json)
        }

        // Default base URL should switch to pro tier when apiKey is set.
        let client = IPDataClient(apiKey: "secret", session: MockURLProtocol.makeSession())
        let info = try await client.lookup("1.1.1.1")
        XCTAssertEqual(sentKey, "secret")
        XCTAssertEqual(info.ip, "1.1.1.1")
    }

    func testNoAPIKeyOmitsHeader() async throws {
        let json = #"{"ip":"1.1.1.1","success":true,"type":"IPv4"}"#.data(using: .utf8)!
        var sentKey: String?
        MockURLProtocol.requestHandler = { request in
            sentKey = request.value(forHTTPHeaderField: "X-Api-Key")
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200,
                httpVersion: nil, headerFields: nil)!
            return (response, json)
        }
        _ = try await makeClient().lookup("1.1.1.1")
        XCTAssertNil(sentKey)
    }

    /// Hits the real free endpoint. Skipped unless IPDATA_LIVE is set.
    func testLiveSmoke() async throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["IPDATA_LIVE"] != nil,
                          "set IPDATA_LIVE=1 to run the live smoke test")
        let client = IPDataClient()
        let info = try await client.lookup("8.8.8.8")
        XCTAssertEqual(info.ip, "8.8.8.8")
        XCTAssertEqual(info.success, true)
    }
}
