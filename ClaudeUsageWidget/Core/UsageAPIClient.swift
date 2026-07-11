import Foundation

enum APIError: Error, LocalizedError {
    case noCookie
    case noOrgID
    case badResponse(Int)
    case decodingFailed(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .noCookie: return String(localized: "error.no_cookie")
        case .noOrgID:  return String(localized: "error.no_org")
        case .badResponse(let code): return String(format: String(localized: "error.server %d"), code)
        case .decodingFailed(let e): return String(format: String(localized: "error.decode %@"), e.localizedDescription)
        case .networkError(let e):   return String(format: String(localized: "error.network %@"), e.localizedDescription)
        }
    }
}

actor UsageAPIClient {
    private let baseURL = "https://claude.ai/api"
    private var cachedOrgID: String?

    func fetchUsage(sessionCookie: String) async throws -> UsageResponse {
        let orgID = try await resolveOrgID(sessionCookie: sessionCookie)
        let url = URL(string: "\(baseURL)/organizations/\(orgID)/usage")!
        let data = try await get(url: url, cookie: sessionCookie)

        do {
            return try JSONDecoder().decode(UsageResponse.self, from: data)
        } catch let decodeErr {
            if let raw = String(data: data, encoding: .utf8) {
                print("[UsageAPIClient] raw response: \(raw.prefix(500))")
            }
            throw APIError.decodingFailed(decodeErr)
        }
    }

    func fetchAccount(sessionCookie: String) async -> AccountResponse? {
        // /api/bootstrap daha kapsamlı dönüyor
        let url = URL(string: "https://claude.ai/api/bootstrap")!
        guard let data = try? await get(url: url, cookie: sessionCookie) else { return nil }

        // Dil alanı var mı logla
        if let raw = String(data: data, encoding: .utf8) {
            let keywords = ["language", "locale", "lang_"]
            let found = keywords.filter { raw.lowercased().contains($0) }
            if !found.isEmpty { print("[Account] Dil alanları bulundu:", found) }
            print("[Account] bootstrap:", raw.prefix(800))
        }

        if let resp = try? JSONDecoder().decode(BootstrapResponse.self, from: data) {
            return resp.account
        }
        // Fallback: doğrudan /api/account dene
        let url2 = URL(string: "https://claude.ai/api/account")!
        guard let data2 = try? await get(url: url2, cookie: sessionCookie) else { return nil }
        return try? JSONDecoder().decode(AccountResponse.self, from: data2)
    }

    private func resolveOrgID(sessionCookie: String) async throws -> String {
        if let id = cachedOrgID { return id }
        let url = URL(string: "\(baseURL)/organizations")!
        let data = try await get(url: url, cookie: sessionCookie)

        if let list = try? JSONDecoder().decode([Organization].self, from: data), let first = list.first {
            cachedOrgID = first.uuid
            return first.uuid
        }
        if let raw = String(data: data, encoding: .utf8) {
            print("[UsageAPIClient] org raw: \(raw.prefix(500))")
        }
        throw APIError.noOrgID
    }

    private func get(url: URL, cookie: String) async throws -> Data {
        var req = URLRequest(url: url)
        req.setValue(cookie, forHTTPHeaderField: "Cookie")
        req.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
        req.setValue("https://claude.ai", forHTTPHeaderField: "Origin")
        req.setValue("https://claude.ai/", forHTTPHeaderField: "Referer")
        req.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        req.setValue("same-origin", forHTTPHeaderField: "Sec-Fetch-Site")
        req.setValue("cors", forHTTPHeaderField: "Sec-Fetch-Mode")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: req)
        } catch {
            throw APIError.networkError(error)
        }

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            if let raw = String(data: data, encoding: .utf8) {
                print("[UsageAPIClient] HTTP \(http.statusCode) body: \(raw.prefix(300))")
            }
            throw APIError.badResponse(http.statusCode)
        }
        return data
    }

    func invalidateOrgCache() {
        cachedOrgID = nil
    }
}
