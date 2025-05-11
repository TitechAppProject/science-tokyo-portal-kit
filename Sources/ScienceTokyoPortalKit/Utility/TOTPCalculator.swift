//
//  TOTPCalculator.swift
//  ScienceTokyoPortalKit
//
//  Created by 中島正矩 on 2025/04/07.
//

import Foundation
#if canImport(CryptoKit)
import CryptoKit
#else
import Crypto
#endif

public enum TOTPError: Error, Equatable {
    case invalidBase32
}

public func calculateTOTP(secret: String, current: Date) throws -> String {
    let unixTime = current.timeIntervalSince1970
    let period = TimeInterval(30)
    // 8byteのデータに変換
    var time = UInt64(unixTime / period).bigEndian
    let timeData = withUnsafeBytes(of: &time) { Array($0) }
    let digits = 6
    guard let secretKey = base32Decode(secret) else {
        throw TOTPError.invalidBase32
    }
    let hash = HMAC<Insecure.SHA1>.authenticationCode(for: timeData, using: SymmetricKey(data: secretKey))
 
    var truncatedHash = hash.withUnsafeBytes { ptr -> UInt32 in
        let offset = ptr[hash.byteCount - 1] & 0x0f
 
        let truncatedHashPtr = ptr.baseAddress! + Int(offset)
        return truncatedHashPtr.bindMemory(to: UInt32.self, capacity: 1).pointee
    }
 
    truncatedHash = UInt32(bigEndian: truncatedHash)
    truncatedHash = truncatedHash & 0x7FFF_FFFF
    truncatedHash = truncatedHash % UInt32(pow(10, Float(digits)))
    return String(format: "%06d", truncatedHash)
}
