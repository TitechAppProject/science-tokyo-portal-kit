//
//  TOTPCalculatorTests.swift
//  ScienceTokyoPortalKit
//
//  Created by nanashiki on 2025/05/11.
//

import Foundation
import ScienceTokyoPortalKit
import Testing

struct TOTPCalculator {
    @Test("正常なSecret")
    func testValidSecret() throws {
        let result = try calculateTOTP(secret: "AAA", current: Date(timeIntervalSinceReferenceDate: 0))
        let expected = "877465"

        #expect(result == expected)
    }

    @Test("不正なSecret")
    func testInvalidSecret() throws {
        do {
            _ = try calculateTOTP(secret: "1", current: Date(timeIntervalSinceReferenceDate: 0))
            Issue.record("例外が発生しない")
        } catch {
            // 例外が発生することを期待
            #expect((error as! TOTPError) == .invalidBase32)
        }
    }
}
