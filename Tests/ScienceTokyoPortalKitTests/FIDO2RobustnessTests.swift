import Foundation
import Testing

@testable import ScienceTokyoPortalKit

#if canImport(CryptoKit)
import CryptoKit
#else
import Crypto
#endif

struct FIDO2RobustnessTests {
    @Test func originAndRPIDAreIndependent() throws {
        let origin = "https://login.example.com:8443"
        let rpId = "example.com"
        let json = try registrationJSON { $0["rp"] = ["id": rpId, "name": "Example"] }
        let privateKey = try Ecc.generatePrivateKey()
        let registration = try #require(try createCredential(from: json, username: "user", privateKey: privateKey, origin: origin))
        #expect(registration.json["origin"] as? String == origin)
        let publicCredential = try #require(registration.json["credential"] as? [String: Any])
        let response = try #require(publicCredential["response"] as? [String: Any])
        let clientData = try #require(Data(base64urlDecodedData: response["clientDataJSON"] as? String ?? ""))
        let registrationClient = try #require(JSONSerialization.jsonObject(with: clientData) as? [String: Any])
        #expect(registrationClient["origin"] as? String == origin)

        var options = try fixtureJSON("FIDO2LoginOptions")
        options["rpId"] = rpId
        let credential = FIDO2Credential(credentialId: "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB", privateKey: privateKey, rpId: registration.rpId)
        let assertion = try #require(try createAssertion(from: jsonString(options), credential: credential, origin: origin))
        let assertionClientData = try #require(Data(base64urlDecodedData: assertion["client_data_json"] ?? ""))
        let assertionClient = try #require(JSONSerialization.jsonObject(with: assertionClientData) as? [String: Any])
        #expect(assertionClient["origin"] as? String == origin)
        let authData = try #require(Data(base64urlDecodedData: assertion["authenticator_data"] ?? ""))
        #expect(Data(authData.prefix(32)) == Data(SHA256.hash(data: Data(rpId.utf8))))
        #expect(try createAssertion(from: jsonString(options), credential: credential, origin: "https://unrelated.example") == nil)
        let wrongCredential = FIDO2Credential(credentialId: credential.credentialId, privateKey: privateKey, rpId: "login.example.com")
        #expect(try createAssertion(from: jsonString(options), credential: wrongCredential, origin: origin) == nil)
    }

    @Test(arguments: [false, true])
    func loginTokenDoesNotDependOnFormID(removeOptionsAttribute: Bool) throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)
        let url = try #require(Bundle.module.url(forResource: "UserNamePage", withExtension: "html"))
        let original = try String(contentsOf: url, encoding: .utf8)
        let expected = try #require(try portal.extractFIDO2AuthenticityToken(html: original))
        var modified = original.replacingOccurrences(of: "id=\"fido2-form\"", with: "id=\"renamed-passkey-form\"")
        if removeOptionsAttribute {
            modified = modified.replacingOccurrences(of: "data-options-path=\"/auth/session/fido2/new\"", with: "")
        }
        #expect(try portal.extractFIDO2AuthenticityToken(html: modified) == expected)
    }

    @Test func loginTokenRejectsEmptyOrAmbiguousForms() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)
        let form = "<form data-options-path='/options'><input name='authenticity_token' value='passkey-token'></form>"
        let passwordForm = "<form><input name='authenticity_token' value='password-token'></form>"
        #expect(try portal.extractFIDO2AuthenticityToken(html: passwordForm + form) == "passkey-token")
        #expect(try portal.extractFIDO2AuthenticityToken(html: form + form) == nil)
        #expect(try portal.extractFIDO2AuthenticityToken(html: form.replacingOccurrences(of: "passkey-token", with: "")) == nil)
    }

    @Test(arguments: ["MacBook", "iPhone", "研究用の端末"])
    func registrationRequestsUseTheChosenDisplayName(displayName: String) throws {
        let settings = FIDO2SettingsRequest(htmlMetas: [], displayName: displayName).generate(userAgent: "test")
        let relay1 = FIDO2Relay1Request(htmlMetas: [], username: "abcd1234", displayName: displayName).generate(userAgent: "test")
        let settingsData = try #require(settings.httpBody)
        let relayData = try #require(relay1.httpBody)
        let settingsBody = try #require(JSONSerialization.jsonObject(with: settingsData) as? [String: Any])
        let relayBody = try #require(JSONSerialization.jsonObject(with: relayData) as? [String: Any])
        #expect(settingsBody["displayName"] as? String == displayName)
        #expect(relayBody["credentialAlias"] as? String == displayName)
    }

    @Test(arguments: [false, true])
    func backupEligibilityIsPreservedDuringAuthentication(isBackupEligible: Bool) throws {
        let privateKey = try Ecc.generatePrivateKey()
        let credential = FIDO2Credential(
            credentialId: "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB", privateKey: privateKey, isBackupEligible: isBackupEligible)
        var attestation = Attestation(credentialId: Data(repeating: 0, count: 32), isBackupEligible: isBackupEligible)
        try attestation.setECPublicKey(publicKey: Ecc.publicKey(from: privateKey))
        let registrationData = try attestation.generateAuthData(rpId: "isct.ex-tic.com")
        let assertion = try #require(try createAssertion(from: jsonString(fixtureJSON("FIDO2LoginOptions")), credential: credential))
        let assertionData = try #require(Data(base64urlDecodedData: assertion["authenticator_data"] ?? ""))
        #expect(registrationData[32] & UInt8(BE) == assertionData[32] & UInt8(BE))
        #expect((assertionData[32] & UInt8(BE) != 0) == isBackupEligible)
        #expect(registrationData[32] & UInt8(BS) == 0)
        #expect(assertionData[32] & UInt8(BS) == 0)
    }

    @Test(arguments: ["Alice Example", "Alice (Research)", "", "abcd1234（isct）"])
    func registrationPreservesRequestedUsername(displayName: String) throws {
        let json = try registrationJSON {
            $0["user"] = ["id": "dXNlcg", "name": "server-account-name", "displayName": displayName]
        }
        let privateKey = try Ecc.generatePrivateKey()
        let registration = try #require(try createCredential(from: json, username: "abcd1234", privateKey: privateKey))
        let user = try #require(registration.json["user"] as? [String: Any])
        #expect(user["name"] as? String == "abcd1234")
    }

    private func registrationJSON(_ update: (inout [String: Any]) -> Void) throws -> String {
        var outer = try fixtureJSON("FIDO2Relay1Response")
        let resultString = try #require(outer["result"] as? String)
        var result = try #require(JSONSerialization.jsonObject(with: Data(resultString.utf8)) as? [String: Any])
        var publicKey = try #require(result["publicKey"] as? [String: Any])
        update(&publicKey)
        result["publicKey"] = publicKey
        outer["result"] = try jsonString(result)
        return try jsonString(outer)
    }

    private func fixtureJSON(_ name: String) throws -> [String: Any] {
        let url = try #require(Bundle.module.url(forResource: name, withExtension: "json"))
        return try #require(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
    }

    private func jsonString(_ object: [String: Any]) throws -> String {
        String(decoding: try JSONSerialization.data(withJSONObject: object), as: UTF8.self)
    }
}
