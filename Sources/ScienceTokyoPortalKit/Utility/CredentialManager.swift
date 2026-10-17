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

/// 入力JSON文字列を元に、WebAuthn認証処理（navigator.credentials.get()相当）を
/// シミュレーションしてログイン用のフォーム値を生成する関数
///
/// - Parameters:
///   - input: /auth/session/fido2/new のレスポンスJSON文字列
///   - credential: ログインに使う FIDO2 資格情報 (登録時に返されたもの)
/// - Returns: /auth/session/fido2 に送るフォーム値。パースに失敗した場合はnil
func createAssertion(from input: String, credential: FIDO2Credential) throws -> [String: String]? {
    guard
        let data = input.data(using: .utf8),
        let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
        let challenge = json["challenge"] as? String,
        !challenge.isEmpty,
        let rpId = json["rpId"] as? String,
        !rpId.isEmpty,
        let allowCredentials = json["allowCredentials"] as? [[String: Any]]
    else {
        return nil
    }
    // 登録した資格情報がサーバー側の許可リストに含まれていることを確認する
    guard allowCredentials.contains(where: { ($0["id"] as? String) == credential.credentialId }) else {
        return nil
    }

    // clientDataJSONの作成 (WebAuthn spec の webauthn.get)
    let clientData: [String: Any] = [
        "type": "webauthn.get",
        "challenge": challenge,
        "origin": "https://\(rpId)",
    ]
    let clientDataJSONData = try JSONSerialization.data(withJSONObject: clientData, options: [])
    let clientDataBase64 = base64url(clientDataJSONData)

    // authenticatorData (37バイト): rpIdHash || flags || signCount
    let rpIdHash = Data(SHA256.hash(data: rpId.data(using: .utf8)!))
    var authData = rpIdHash
    authData.append(UInt8(UP | UV))  // UP | UV
    withUnsafeBytes(of: UInt32(0).bigEndian) { authData.append(contentsOf: $0) }

    // 署名対象: authenticatorData || SHA256(clientDataJSON)
    let signedData = authData + Data(SHA256.hash(data: clientDataJSONData))
    let signature = try Ecc.sign(message: signedData, privateKey: credential.privateKey)

    return [
        "credential_id": credential.credentialId,
        "client_data_json": clientDataBase64,
        "authenticator_data": base64url(authData),
        "signature": base64url(signature),
    ]
}

/// 登録処理の出力結果
struct RegistrationOutput {
    /// relay2 に送るJSON辞書
    let json: [String: Any]
    /// 資格情報ID (base64url)。ログイン時に必要
    let credentialId: String
}
