import Foundation
import Security
import CryptoKit

/// 入力JSON文字列を元に、WebAuthn登録処理（navigator.credentials.create()相当）をシミュレーションして出力JSON文字列を生成する関数
///
/// - Parameter input: 外部から渡されるJSON文字列
/// - Returns: JSON文字列（辞書型）
func createCredential(from input: String) throws -> [String: Any]? {
    // 1. 外側のJSONをパース
    guard let outerData = input.data(using: .utf8),
          let outerJSON = try? JSONSerialization.jsonObject(with: outerData, options: []) as? [String: Any],
          let resultString = outerJSON["result"] as? String,
          let resultData = resultString.data(using: .utf8),
          let resultJSON = try? JSONSerialization.jsonObject(with: resultData, options: []) as? [String: Any],
          let publicKeyDict = resultJSON["publicKey"] as? [String: Any],
          let rpDict = publicKeyDict["rp"] as? [String: Any],
          let rpId = rpDict["id"] as? String,
          let userDict = publicKeyDict["user"] as? [String: Any],
          let displayName = userDict["displayName"] as? String,
          let challengeStr = publicKeyDict["challenge"] as? String
    else {
        print("入力JSONのパースに失敗")
        return nil
    }
    
    // ユーザー名は"displayName"から括弧より前を抽出
    let userName: String = {
        if let idx = displayName.firstIndex(of: "(") {
            return String(displayName[..<idx])
        }
        return displayName
    }()
    
    // 2. clientDataJSONの作成
    let clientData: [String: Any] = [
        "type": "webauthn.create",
        // 通常はサーバーからのチャレンジをそのまま用います（Base64URLエンコードされた値）
        "challenge": challengeStr,
        "origin": "https://\(rpId)",
        "crossOrigin": false
    ]
    guard let clientDataJSONData = try? JSONSerialization.data(withJSONObject: clientData, options: []),
          let clientDataJSONString = String(data: clientDataJSONData, encoding: .utf8)
    else {
        print("clientDataJSONの生成に失敗")
        return nil
    }
    let clientDataBase64 = clientDataJSONString.data(using: .utf8)!.base64EncodedString()
    
    
    
    // https://qiita.com/tucur-prg/items/b8ca3b678ea6a5d2da03
    // このコードでは秘密鍵の保存名に利用、本来は別の登録と被らないようにしないといけない
    let recordIdentifier = "sample"
    
    var credentialId: Data?
    
    var attestationObject: Data?
    
    let ecc = Ecc(alias: recordIdentifier)
    
    let key = try ecc.getPublicKey()
    
    let attestation = Attestation(rpId: rpId)
    try attestation.setECPublicKey(publicKey: key)
    credentialId = attestation.getCredentialId()
    let rawIdBase64 = credentialId!.base64EncodedString()
    // base64URL形式："+"→"-", "/"→"_"、パディング"="を除去
    let idBase64Url = rawIdBase64
        .replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "/", with: "_")
        .replacingOccurrences(of: "=", with: "")
    attestationObject = try attestation.toCBOR()
    let output: [String: Any] = [
        "origin": "https://\(rpId)",
        "user": [
            "name": userName
        ],
        "rp": [
            "id": rpId
        ],
        "credential": [
            "id": idBase64Url,
            "type": "public-key",
            "rawId": rawIdBase64,
            "response": [
                "clientDataJSON": clientDataBase64,
                "attestationObject": attestationObject!.base64EncodedString()
            ]
        ]
    ]
    return output
}
