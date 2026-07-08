// Quickstart example for the ipdata.info Swift SDK.
// Run: swift run ipdata-example
import Foundation
import IPData

@main
struct IPDataExample {
    static func main() async {
        // Free tier -- no API key needed. For higher limits + batch, get a
        // free key at https://ipdata.info/register and pass it to
        // IPDataClient(apiKey:).
        let client = IPDataClient()

        do {
            let info = try await client.lookup("8.8.8.8")
            print("\(info.ip ?? "?") is in \(info.city ?? "?"), \(info.country ?? "?") "
                + "(ASN \(info.asn.map(String.init) ?? "?") -- \(info.asnOrg ?? "?"))")

            let threat = try await client.threatDomain("example.com")
            print("example.com listed as a threat: \(threat.listed ?? false)")
        } catch {
            print("ipdata request failed: \(error)")
        }
    }
}
