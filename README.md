# IPData.info Swift SDK — Free IP Geolocation & Threat Intelligence API

[![Swift Package Manager](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager/) [![CI](../../actions/workflows/ci.yml/badge.svg)](../../actions/workflows/ci.yml) [![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)

Official Swift client for [**ipdata.info**](https://ipdata.info) — a free,
fast IP geolocation, ASN, and threat-intelligence API. Look up country, city,
ASN, timezone, currency, and security flags (proxy/VPN/Tor/hosting) for any IPv4
or IPv6 address. Powered by [ipdata.info](https://ipdata.info).

## Get a free API key

The public endpoint is **free — 50 requests/min, no signup, no key**. For higher
rate limits and batch lookups, [**create a free API key at
ipdata.info/register**](https://ipdata.info/register) and manage it in your
[dashboard](https://ipdata.info/dashboard).

## Install

Add the package to your `Package.swift`:

```swift
.package(url: "https://github.com/IPDataInfo/ipdata-swift", from: "0.1.0")
```

Or in Xcode: **File → Add Package Dependencies…** and enter
`https://github.com/IPDataInfo/ipdata-swift`.

## Quickstart

```swift
import IPData

let client = IPDataClient() // free tier; or IPDataClient(apiKey: "KEY")

let info = try await client.lookup("8.8.8.8")
print(info.city ?? "", info.country ?? "", info.asnOrg ?? "")
// Mountain View United States Google LLC
```

## Methods

| Method | What it returns |
|--------|-----------------|
| `lookup(ip?)` | Full geolocation record (own IP if omitted) |
| `geo(ip)` | Geo subset (city/region/country/lat/lon/tz) |
| `asn(ip)` | ASN + ISP/registry for an IP |
| `batch(ips)` | Many IPs at once (**requires an API key**) |
| `asnDetail(n)` | ASN detail incl. prefixes |
| `asnWhoisHistory(n)` | ASN whois history |
| `asnChanges()` | ASN change feed |
| `threatDomain/threatHash/threatURL(x)` | Threat-intel lookup (domain / file hash / URL) |

Full response schema: [ipdata.info API docs](https://ipdata.info/docs) ·
[SDK contract](https://ipdata.info/docs/sdks).

## Configuration

```swift
let client = IPDataClient(
    apiKey: "KEY",                                 // sent as X-Api-Key; switches to pro.ipdata.info
    baseURL: URL(string: "https://ipdata.info"),
    timeout: 10,
    session: customURLSession                       // optional, e.g. for testing
)
```

Errors from non-2xx responses are thrown as `IPDataError` with `status` and
`message`.

## Rate limits

- Free (`ipdata.info`): 50 req/min, no key.
- Paid (`pro.ipdata.info`): higher limits + `batch`, with an
  [API key](https://ipdata.info/register).

## Other SDKs

12 official SDKs — see the full list at
[**ipdata.info/docs/sdks**](https://ipdata.info/docs/sdks): Python, Node.js, Go,
PHP, Java, Rust, .NET, Kotlin, Swift, Dart, Bash, Objective-C.

## License

MIT © [ipdata.info](https://ipdata.info)
