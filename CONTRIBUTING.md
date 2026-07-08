# Contributing

Thanks for considering a contribution to the ipdata.info Swift SDK.

## Setup

```
swift build
swift test
```

## Guidelines

- Keep the public API in sync with [`docs/sdk-api-contract.md`](https://ipdata.info/docs/sdks)
  — every official ipdata SDK maps 1:1 to the same methods and behavior.
- No third-party dependencies; the SDK is built on `URLSession` + `Codable`
  only.
- Add or update tests in `Tests/IPDataTests` for any behavior change.
- Run `swift build` and `swift test` before opening a pull request.

## Reporting issues

Please open a GitHub issue with a minimal reproduction. Do not include a live
API key in bug reports.
