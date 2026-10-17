import Foundation
import Testing

@testable import ScienceTokyoPortalKit

struct FIDO2RobustnessTests {
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
