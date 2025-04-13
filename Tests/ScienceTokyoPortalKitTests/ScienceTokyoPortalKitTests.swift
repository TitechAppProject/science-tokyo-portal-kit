import Testing
import Foundation
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
    try await portal.setFIDO2()
}
*/

@Test func testTOTPLogin() async throws {
    let account = ScienceTokyoPortalAccount(username: "username", password: "password", totpSecret: "xxxxxxxx")
    let portal = ScienceTokyoPortal(urlSession: .shared)
    let loginPageHtml = try await portal.loginCommon(account: account)
    try await portal.loginTOTP(account: account, methodSelectionPageHtml: loginPageHtml)
}

@Test func testTOTPGeneration() async throws {
    let totpSecret = "@"
    #expect(throws: TOTPError.invalidBase32) {
        try calculateTOTP(secret: totpSecret)
    }
}
 
/*
@Test func passkey() async throws {
    let inputJSON = """
    {"result":"{\\"trId\\":\\"xxxxxxxx\\",\\"publicKey\\":{\\"rp\\":{\\"id\\":\\"isct.ex-tic.com\\",\\"name\\":\\"isct.ex-tic.com\\"},\\"user\\":{\\"displayName\\":\\"xxxx(isct)\\",\\"id\\":\\"xxxxxxxx\\",\\"name\\":\\"xxxx(isct)\\",\\"icon\\":\\"\\"},\\"challenge\\":\\"xxxxxx\\",\\"pubKeyCredParams\\":[{\\"type\\":\\"public-key\\",\\"alg\\":-257},{\\"type\\":\\"public-key\\",\\"alg\\":-258},{\\"type\\":\\"public-key\\",\\"alg\\":-259},{\\"type\\":\\"public-key\\",\\"alg\\":-260},{\\"type\\":\\"public-key\\",\\"alg\\":-261},{\\"type\\":\\"public-key\\",\\"alg\\":-35},{\\"type\\":\\"public-key\\",\\"alg\\":-36},{\\"type\\":\\"public-key\\",\\"alg\\":-37},{\\"type\\":\\"public-key\\",\\"alg\\":-38},{\\"type\\":\\"public-key\\",\\"alg\\":-39},{\\"type\\":\\"public-key\\",\\"alg\\":-65535},{\\"type\\":\\"public-key\\",\\"alg\\":-7},{\\"type\\":\\"public-key\\",\\"alg\\":-8}],\\"timeout\\":30000,\\"authenticatorSelection\\":{\\"requireResidentKey\\":true,\\"userVerification\\":\\"required\\"},\\"attestation\\":\\"direct\\",\\"extensions\\":{\\"biometricPerfBounds\\":{\\"FAR\\":0.0,\\"FRR\\":0.0}}},\\"challengeToken\\":\\"xxxxxxxx\\"}","statusCode":1200}
    """
    
    if let outputJSON = createCredential(from: inputJSON) {
        print("生成された出力JSON:")
        print(outputJSON)
    } else {
        print("クレデンシャル生成に失敗しました")
    }
}
*/

