import Foundation

/// WebAuthnで利用できるorigin。パス・クエリを除き、既定ポートを正規化する。
struct FIDO2Origin: Equatable {
    let value: String
    let host: String

    init?(url: URL) {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true),
            let scheme = components.scheme?.lowercased(), let host = components.host?.lowercased(),
            components.user == nil, components.password == nil,
            scheme == "https" || (scheme == "http" && ["localhost", "127.0.0.1", "[::1]"].contains(host))
        else {
            return nil
        }
        components.scheme = scheme
        components.host = host
        if components.port == (scheme == "https" ? 443 : 80) {
            components.port = nil
        }
        components.path = ""
        components.query = nil
        components.fragment = nil
        guard let value = components.string else { return nil }
        self.value = value
        self.host = host
    }
}
