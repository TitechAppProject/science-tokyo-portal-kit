import Foundation

#if canImport(CryptoKit)
import CryptoKit
#else
import Crypto
#endif

/// base64urlエンコード (パディングなし)
func base64url(_ data: Data) -> String {
    data.base64EncodedString()
        .replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "/", with: "_")
        .replacingOccurrences(of: "=", with: "")
}

/// 暗号学的な乱数バイト列を生成する
func randomBytes(_ count: Int) -> Data {
    var generator = SystemRandomNumberGenerator()
    return Data((0..<count).map { _ in UInt8.random(in: 0...255, using: &generator) })
}

/// 入力JSON文字列を元に、WebAuthn登録処理（navigator.credentials.create()相当）を
/// シミュレーションして出力JSON文字列を生成する関数
///
/// - Parameters:
///   - input: relay1 のレスポンスJSON文字列
///   - username: ユーザー名
///   - privateKey: P-256 秘密鍵 (生32バイト)
/// - Returns: 登録結果 (relay2 に送るJSON辞書と資格情報ID)。パースに失敗した場合はnil
func createCredential(from input: String, username: String, privateKey: Data) throws -> RegistrationOutput? {
    // 1. 外側のJSONをパース
    guard
        let outerData = input.data(using: .utf8),
        let outerJSON = try? JSONSerialization.jsonObject(with: outerData, options: []) as? [String: Any],
        let resultString = outerJSON["result"] as? String,
        let resultData = resultString.data(using: .utf8),
        let resultJSON = try? JSONSerialization.jsonObject(with: resultData, options: []) as? [String: Any],
        let publicKeyDict = resultJSON["publicKey"] as? [String: Any],
        let rpDict = publicKeyDict["rp"] as? [String: Any],
        let rpId = rpDict["id"] as? String,
        let userDict = publicKeyDict["user"] as? [String: Any],
        let challengeStr = publicKeyDict["challenge"] as? String
    else {
        // 入力JSONのパースに失敗
        return nil
    }

    // ユーザー名は"displayName"から括弧より前を抽出
    let displayName = userDict["displayName"] as? String ?? username
    let userName: String = {
        if let idx = displayName.firstIndex(of: "(") {
            return String(displayName[..<idx])
        }
        return displayName
    }()

    // 2. clientDataJSONの作成
    let clientData: [String: Any] = [
        "type": "webauthn.create",
        "challenge": challengeStr,
        "origin": "https://\(rpId)",
    ]
    let clientDataJSONData = try JSONSerialization.data(withJSONObject: clientData, options: [])
    let clientDataBase64 = base64url(clientDataJSONData)

    // 3. 公開鍵の導出 (秘密鍵は保存せず、呼び出し側が保持する)
    let publicKey = try Ecc.publicKey(from: privateKey)

    // 4. attestationObjectの生成
    let credentialId = randomBytes(32)
    let credentialIdBase64 = base64url(credentialId)

    var attestation = Attestation(credentialId: credentialId)
    try attestation.setECPublicKey(publicKey: publicKey)
    let attestationObject = try attestation.toCBOR(rpId: rpId)

    // 5. relay2 に送る出力JSONの作成
    // OnepassFido2.exgen.js の reqResponseReg と同じ形式にする:
    //   - id: base64url (WebAuthnの result.id)
    //   - rawId: standard base64 (btoa形式, パディング付き)
    //   - response.clientDataJSON / attestationObject: base64url
    let output: [String: Any] = [
        "origin": "https://\(rpId)",
        "user": [
            "name": userName
        ],
        "rp": [
            "id": rpId
        ],
        "credential": [
            "id": credentialIdBase64,
            "type": "public-key",
            "rawId": credentialId.base64EncodedString(),
            "response": [
                "clientDataJSON": clientDataBase64,
                "attestationObject": base64url(attestationObject),
            ],
        ],
    ]
    return RegistrationOutput(json: output, credentialId: credentialIdBase64)
}

/// 登録処理の出力結果
struct RegistrationOutput {
    /// relay2 に送るJSON辞書
    let json: [String: Any]
    /// 資格情報ID (base64url)。ログイン時に必要
    let credentialId: String
}
