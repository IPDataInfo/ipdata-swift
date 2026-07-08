import Foundation

/// Full geolocation record returned by ``IPDataClient/lookup(_:)``. The API
/// omits null/empty fields, so nearly every property is optional.
public struct IPInfo: Codable, Sendable, Equatable {
    public let ip: String?
    public let success: Bool?
    public let type: String?
    public let continent: String?
    public let continentCode: String?
    public let country: String?
    public let countryCode: String?
    public let region: String?
    public let city: String?
    public let latitude: Double?
    public let longitude: Double?
    public let isEU: Bool?
    public let timezone: String?
    public let zip: String?
    public let postal: String?
    public let callingCode: String?
    public let capital: String?
    public let borders: String?
    public let asn: Int?
    public let asnOrg: String?
    public let isp: String?
    public let registry: String?
    public let isProxy: Bool?
    public let isHosting: Bool?
    public let network: Network?
    public let flag: Flag?
    public let connection: Connection?
    public let timeZone: TimeZoneInfo?
    public let currency: Currency?
    public let security: Security?

    enum CodingKeys: String, CodingKey {
        case ip, success, type, continent
        case continentCode = "continent_code"
        case country
        case countryCode = "country_code"
        case region, city, latitude, longitude
        case isEU = "is_eu"
        case timezone, zip, postal
        case callingCode = "calling_code"
        case capital, borders, asn
        case asnOrg = "asn_org"
        case isp, registry
        case isProxy = "is_proxy"
        case isHosting = "is_hosting"
        case network, flag, connection
        case timeZone = "time_zone"
        case currency, security
    }
}

/// ASN/route block nested under `network`.
public struct Network: Codable, Sendable, Equatable {
    public let asn: Int?
    public let asName: String?
    public let route: String?
    public let registryCountry: String?

    enum CodingKeys: String, CodingKey {
        case asn
        case asName = "as_name"
        case route
        case registryCountry = "registry_country"
    }
}

/// Country flag image + emoji representations.
public struct Flag: Codable, Sendable, Equatable {
    public let img: String?
    public let emoji: String?
    public let emojiUnicode: String?

    enum CodingKeys: String, CodingKey {
        case img, emoji
        case emojiUnicode = "emoji_unicode"
    }
}

/// Connection (ASN/org/ISP) block.
public struct Connection: Codable, Sendable, Equatable {
    public let asn: Int?
    public let org: String?
    public let isp: String?
    public let domain: String?
}

/// Enriched timezone object nested under `time_zone`.
public struct TimeZoneInfo: Codable, Sendable, Equatable {
    public let id: String?
    public let abbr: String?
    public let isDST: Bool?
    public let offset: Int?
    public let utc: String?
    public let currentTime: String?

    enum CodingKeys: String, CodingKey {
        case id, abbr
        case isDST = "is_dst"
        case offset, utc
        case currentTime = "current_time"
    }
}

/// Country currency block.
public struct Currency: Codable, Sendable, Equatable {
    public let name: String?
    public let code: String?
    public let symbol: String?
}

/// Anonymity/threat flags for the IP.
public struct Security: Codable, Sendable, Equatable {
    public let anonymous: Bool?
    public let proxy: Bool?
    public let vpn: Bool?
    public let tor: Bool?
    public let hosting: Bool?
}

/// Compact geo subset returned by ``IPDataClient/geo(_:)``.
public struct GeoInfo: Codable, Sendable, Equatable {
    public let ip: String?
    public let city: String?
    public let region: String?
    public let country: String?
    public let countryCode: String?
    public let latitude: Double?
    public let longitude: Double?
    public let timezone: String?
    public let zip: String?

    enum CodingKeys: String, CodingKey {
        case ip, city, region, country
        case countryCode = "country_code"
        case latitude, longitude, timezone, zip
    }
}

/// Compact ASN subset returned by ``IPDataClient/asn(_:)``.
public struct ASNBrief: Codable, Sendable, Equatable {
    public let ip: String?
    public let asn: Int?
    public let asnOrg: String?
    public let isp: String?
    public let registry: String?

    enum CodingKeys: String, CodingKey {
        case ip, asn
        case asnOrg = "asn_org"
        case isp, registry
    }
}

/// Result of a threat lookup (``IPDataClient/threatDomain(_:)``,
/// ``IPDataClient/threatHash(_:)``, ``IPDataClient/threatURL(_:)``). When
/// `listed` is false, the remaining fields are absent.
public struct ThreatMatch: Codable, Sendable, Equatable {
    public let value: String?
    public let iocType: String?
    public let listed: Bool?
    public let threatType: String?
    public let sources: [String]?
    public let confidence: Int?
    public let firstSeen: String?
    public let lastSeen: String?

    enum CodingKeys: String, CodingKey {
        case value
        case iocType = "ioc_type"
        case listed
        case threatType = "threat_type"
        case sources, confidence
        case firstSeen = "first_seen"
        case lastSeen = "last_seen"
    }
}

/// Opaque JSON value used for the loosely-structured `asnDetail`,
/// `asnWhoisHistory`, and `asnChanges` responses (large/paginated shapes that
/// the SDK passes through rather than modeling field-by-field).
public enum JSONValue: Codable, Sendable, Equatable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Unsupported JSON value")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }
}
