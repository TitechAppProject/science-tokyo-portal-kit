import Foundation
import Testing

@testable import ScienceTokyoPortalKit

/*
@Test func testEmail() async throws {
    // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    let account = ScienceTokyoAccount(username: "username", password: "password", totpSecret: nil)
    let portal = ScienceTokyoPortal(urlSession: .shared)
    //ログイン
    let loginPageHtml = try await portal.loginCommon(account: account)
    let (otpPageInputs, methodSelectionPageMetas) = try await portal.loginEmail(account: account, methodSelectionPageHtml: loginPageHtml)
    let otp = "123456" // ここに実際のOTPを入力してください
    /// OTPの送信
    try await portal.latterEmailLogin(htmlInputs: otpPageInputs, htmlMetas: methodSelectionPageMetas, otp: otp)
}
*/
//
//@Test func testTOTPLogin() async throws {
//    let account = ScienceTokyoPortalAccount(username: "username", password: "password", totpSecret: "xxxxxxxx")
//    let portal = ScienceTokyoPortal(urlSession: .shared)
//    let loginPageHtml = try await portal.loginCommon(account: account)
//    try await portal.loginTOTP(account: account, methodSelectionPageHtml: loginPageHtml)
//    try await portal.getLMSDashboard()
//    print("wstoken=", try await portal.getLMSToken())
//}
