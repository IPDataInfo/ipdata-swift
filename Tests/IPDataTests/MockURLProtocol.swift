import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A `URLProtocol` stub that lets tests intercept `URLSession` requests and
/// return canned responses without touching the network.
final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    /// Set by each test before making a request. Receives the request and
    /// returns (httpResponse, body).
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            fatalError("MockURLProtocol.requestHandler not set")
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}

    /// Builds a `URLSession` wired to this mock protocol.
    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}
