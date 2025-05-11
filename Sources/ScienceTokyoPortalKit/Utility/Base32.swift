//
//  Base32.swift
//  ScienceTokyoPortalKit
//
//  Created by 中島正矩 on 2025/04/07.
//

import Foundation

func base32Decode(_ base32String: String) -> Data? {
    // Base32のアルファベットマッピング（A-Zと2-7）
    let base32Alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
    var lookup: [Character: UInt8] = [:]
    for (i, c) in base32Alphabet.enumerated() {
        lookup[c] = UInt8(i)
    }

    // パディング（"="）や空白を削除し、大文字に変換
    let cleanedString =
        base32String
        .replacingOccurrences(of: "=", with: "")
        .replacingOccurrences(of: " ", with: "")
        .uppercased()

    var buffer: UInt = 0
    var bitsLeft = 0
    var result = Data()

    // 1文字ずつデコード
    for char in cleanedString {
        // 不正な文字の場合はnilを返す
        guard let value = lookup[char] else {
            return nil
        }

        buffer = (buffer << 5) | UInt(value)
        bitsLeft += 5

        // 8ビット以上溜まったら1バイトずつ取り出す
        if bitsLeft >= 8 {
            bitsLeft -= 8
            let byte = UInt8((buffer >> bitsLeft) & 0xFF)
            result.append(byte)
        }
    }

    return result
}
