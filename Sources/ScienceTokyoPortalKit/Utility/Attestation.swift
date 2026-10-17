import Foundation

#if canImport(CryptoKit)
import CryptoKit
#else
import Crypto
#endif

/// WebAuthn 登録時の attestation データ (authData / attestationObject) を組み立てる。
/// fmt は "none" (ソフトウェアオーセンティケータのため信頼できる証明チェーンを持たない)。
struct Attestation {
    /// "none" attestation では AAGUID は全て0にする (WebAuthn仕様)
    var aaguid: Data = Data(repeating: 0, count: 16)
    var credentialId: Data
    var credentialPublicKey: Data?
    let isBackupEligible: Bool

    init(credentialId: Data, isBackupEligible: Bool = true) {
        self.credentialId = credentialId
        self.isBackupEligible = isBackupEligible
    }

    /// SEC1形式 (0x04 || x || y) の公開鍵から COSE key を組み立てる
    mutating func setECPublicKey(publicKey: Data) throws {
        // publicKeyの長さは65バイト
        guard publicKey.count == 65 else {
            throw NSError(domain: "publicKey length is invalid", code: 0, userInfo: nil)
        }
        let coseKey = CBOREncoder.Value.map([
            (.unsignedInt(1), .unsignedInt(UInt64(EC2))),  // kty: EC2
            (.unsignedInt(3), .negativeInt(Int64(ES256))),  // alg: ES256
            (.negativeInt(Int64(-1)), .unsignedInt(UInt64(COSE_P256))),  // crv: P-256
            (.negativeInt(Int64(-2)), .byteString(publicKey.subdata(in: 1..<33))),  // x
            (.negativeInt(Int64(-3)), .byteString(publicKey.subdata(in: 33..<65))),  // y
        ])
        credentialPublicKey = CBOREncoder.encode(coseKey)
    }

    func generateAuthData(rpId: String) throws -> Data {
        guard let credentialPublicKey = credentialPublicKey else {
            throw NSError(domain: "credentialPublicKey is empty", code: 0, userInfo: nil)
        }

        var authData: Data = Data()

        // rpIdHash (SHA-256 of rpId)
        authData.append(Data(SHA256.hash(data: rpId.data(using: .utf8)!)))
        // 秘密鍵はエクスポート可能だが、バックアップの実施状況は管理しないためBSは設定しない。
        authData.append(UInt8(UP | UV | AT | (isBackupEligible ? BE : 0)))
        // signCount
        withUnsafeBytes(of: UInt32(0).bigEndian) { authData.append(contentsOf: $0) }
        // aaguid
        authData.append(aaguid)
        // credentialId length (2 bytes) + credentialId
        withUnsafeBytes(of: UInt16(credentialId.count).bigEndian) { authData.append(contentsOf: $0) }
        authData.append(credentialId)
        // credentialPublicKey
        authData.append(credentialPublicKey)

        return authData
    }

    func toCBOR(rpId: String) throws -> Data {
        let attestationObject = CBOREncoder.Value.map([
            (.textString("fmt"), .textString("none")),
            (.textString("attStmt"), .map([])),
            (.textString("authData"), .byteString(try generateAuthData(rpId: rpId))),
        ])
        return CBOREncoder.encode(attestationObject)
    }
}
