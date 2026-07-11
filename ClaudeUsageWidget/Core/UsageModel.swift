import Foundation

struct UsageResponse: Codable {
    let fiveHour: UsagePeriod?
    let sevenDay: UsagePeriod?
    let sevenDayOpus: UsagePeriod?
    let sevenDaySonnet: UsagePeriod?
    let sevenDayOauthApps: UsagePeriod?
    let sevenDayCowork: UsagePeriod?
    let sevenDayOmelette: UsagePeriod?  // Opus promotional
    let tangelo: UsagePeriod?            // Fable / Claude Code
    let iguanaNecktie: UsagePeriod?
    let nimbusQuill: UsagePeriod?
    let omelettPromotional: UsagePeriod?

    enum CodingKeys: String, CodingKey {
        case fiveHour             = "five_hour"
        case sevenDay             = "seven_day"
        case sevenDayOpus         = "seven_day_opus"
        case sevenDaySonnet       = "seven_day_sonnet"
        case sevenDayOauthApps    = "seven_day_oauth_apps"
        case sevenDayCowork       = "seven_day_cowork"
        case sevenDayOmelette     = "seven_day_omelette"
        case tangelo              = "tangelo"
        case iguanaNecktie        = "iguana_necktie"
        case nimbusQuill          = "nimbus_quill"
        case omelettPromotional   = "omelette_promotional"
    }
}

struct UsagePeriod: Codable {
    let utilization: Double?
    let resetsAt: String?
    let limitDollars: Double?
    let usedDollars: Double?
    let remainingDollars: Double?

    enum CodingKeys: String, CodingKey {
        case utilization
        case resetsAt         = "resets_at"
        case limitDollars     = "limit_dollars"
        case usedDollars      = "used_dollars"
        case remainingDollars = "remaining_dollars"
    }

    var resetDate: Date? {
        guard let raw = resetsAt else { return nil }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return iso.date(from: raw) ?? ISO8601DateFormatter().date(from: raw)
    }

    var percent: Double { utilization ?? 0 }
    var isNull: Bool { utilization == nil && resetsAt == nil }
}

struct Organization: Codable {
    let uuid: String
    let name: String?
}

struct AccountResponse: Codable {
    let uuid: String?
    let emailAddress: String?
    let fullName: String?
    let displayName: String?

    enum CodingKeys: String, CodingKey {
        case uuid
        case emailAddress = "email_address"
        case fullName     = "full_name"
        case displayName  = "display_name"
    }
}

struct BootstrapResponse: Codable {
    let account: AccountResponse?
}
