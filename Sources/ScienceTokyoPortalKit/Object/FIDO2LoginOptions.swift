import Foundation

/// WebAuthnの既定値を適用した認証オプション。
struct FIDO2LoginOptions {
    struct Credential: Decodable {
        let type: String
        let id: String
    }

    private struct Payload: Decodable {
        let challenge: String
        let rpId: String?
        let allowCredentials: [Credential]?
    }

    let challenge: String
    let rpId: String
    let allowCredentials: [Credential]

    init?(json: String, origin: FIDO2Origin) {
        guard let payload = try? JSONDecoder().decode(Payload.self, from: Data(json.utf8)), !payload.challenge.isEmpty else { return nil }
        let rpId = payload.rpId ?? origin.host
        let credentials = payload.allowCredentials ?? []
        guard origin.allows(rpId: rpId), credentials.allSatisfy({ !$0.id.isEmpty }) else { return nil }
        self.challenge = payload.challenge
        self.rpId = rpId
        self.allowCredentials = credentials
    }
}
