import Foundation

#if canImport(CryptoKit)
import CryptoKit
#else
import Crypto
#endif

/// WebAuthn 用の P-256 鍵ペア操作。
/// 鍵の生成・公開鍵導出・署名のみを行い、鍵を内部で保存しない。
/// 秘密鍵は生の P-256 スカラー値 (32バイト) として扱い、呼び出し側が保持する。
enum Ecc {
    /// P-256 秘密鍵 (生32バイト) を生成する
    static func generatePrivateKey() throws -> Data {
        P256.Signing.PrivateKey().rawRepresentation
    }

    /// 秘密鍵から公開鍵を取得する
    /// - Parameter privateKey: P-256 秘密鍵 (生32バイト)
    /// - Returns: SEC1形式 (0x04 || x || y, 65バイト) の公開鍵
    static func publicKey(from privateKey: Data) throws -> Data {
        let key = try P256.Signing.PrivateKey(rawRepresentation: privateKey)
        return key.publicKey.x963Representation
    }

    /// メッセージに ES256 (ECDSA over SHA-256) の署名を行う
    /// - Parameters:
    ///   - message: 署名対象のメッセージ
    ///   - privateKey: P-256 秘密鍵 (生32バイト)
    /// - Returns: DER形式の署名 (サーバーが検証できる形式)
    static func sign(message: Data, privateKey: Data) throws -> Data {
        let key = try P256.Signing.PrivateKey(rawRepresentation: privateKey)
        let signature = try key.signature(for: message)
        return rawToDER(signature.rawRepresentation)
    }

    /// ECDSA署名を raw形式 (r||s, 64バイト) から DER形式へ変換する
    private static func rawToDER(_ raw: Data) -> Data {
        func derInteger(_ bytes: Data) -> Data {
            var b = [UInt8](bytes)
            while b.first == 0 { b.removeFirst() }
            if b.isEmpty { b = [0] }
            if b[0] & 0x80 != 0 { b.insert(0, at: 0) }
            return Data([0x02, UInt8(b.count)]) + Data(b)
        }
        let r = derInteger(Data(raw.prefix(32)))
        let s = derInteger(Data(raw.suffix(32)))
        let body = r + s
        return Data([0x30, UInt8(body.count)]) + body
    }
}
