import XCTest

@testable import ScienceTokyoPortalKit

final class ScienceTokyoPortalKitTests: XCTestCase {
    func testUserNamePageValidation() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)

        let html = try! String(contentsOf: Bundle.module.url(forResource: "UserNamePage", withExtension: "html")!)

        XCTAssertTrue(try! portal.validateUserNamePage(html: html))
    }

    func testUserNamePageMetas() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)

        let html = try! String(contentsOf: Bundle.module.url(forResource: "UserNamePage", withExtension: "html")!)

        let metas = try! portal.parseHTMLMeta(html: html)

        XCTAssertEqual(
            metas,
            [
                HTMLMeta(name: "charset", content: "utf-8"),
                HTMLMeta(name: "X-UA-Compatible", content: "IE=edge"),
                HTMLMeta(name: "viewport", content: "width=device-width, initial-scale=1"),
                HTMLMeta(name: "csrf-param", content: "authenticity_token"),
                HTMLMeta(name: "csrf-token", content: "MCBhQD3s41D_Sisw0w_tpE2sTYhULaKvmOW9LVohQSI8xXVGjvR2rc8z0rpRpG-mjFb1-YJ4v8i-T8DyHiPsLA")
            ]
        )
    }

    func testUserNamePageParseHTMLInputs() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)

        let html = try! String(contentsOf: Bundle.module.url(forResource: "UserNamePage", withExtension: "html")!)

        let extractedHtml = try! portal.extractHTML(html: html, cssSelector: "div#identifier-field-wrapper")
        let inputs = try! portal.parseHTMLInput(html: extractedHtml)

        XCTAssertEqual(
            inputs,
            [
                HTMLInput(name: "identifier", type: .text, value: ""),
            ]
        )
    }

    func testUserNamePageSubmitJsonValidation() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)
        let account = ScienceTokyoPortalAccount(username: "abcd1234", password: "password", totpSecret: nil)

        let json = try! String(contentsOf: Bundle.module.url(forResource: "UserNamePageSubmit", withExtension: "json")!)

        XCTAssertTrue(try! portal.validateUserNamePageSubmitJson(json: json, account: account))
    }

    func testParsePasswordPageInputs() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)

        let html = try! String(contentsOf: Bundle.module.url(forResource: "UserNamePage", withExtension: "html")!)

        let extractedHtml = try! portal.extractHTML(html: html, cssSelector: "form#login")
        let inputs = try! portal.parseHTMLInput(html: extractedHtml)

        XCTAssertEqual(
            inputs,
            [
                HTMLInput(name: "utf8", type: .hidden, value: "✓"),
                HTMLInput(name: "authenticity_token", type: .hidden, value: "-ZZOqjVkdg1heh6dmdxsoUfrx6PIB04RslZIjk3EW79lq11bk7lhErp4seE34Bzy23959IC2DUVeUUA2FSMWhA"),
                HTMLInput(name: "identifier", type: .text, value: ""),
                HTMLInput(name: "password", type: .password, value: ""),
            ]
        )
    }

    func testPasswordPageSubmitScriptValidation() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)

        let script = try! String(contentsOf: Bundle.module.url(forResource: "PasswordPageSubmitScript", withExtension: "js")!)

        XCTAssertTrue(portal.validateSubmitScript(script: script))
    }

    func testMethodSelectionPageValidation() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)

        let html = try! String(contentsOf: Bundle.module.url(forResource: "MethodSelectionPage", withExtension: "html")!)

        XCTAssertTrue(try! portal.validateMethodSelectionPage(html: html))
    }

    func testMethodSelectionPageMetas() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)

        let html = try! String(contentsOf: Bundle.module.url(forResource: "MethodSelectionPage", withExtension: "html")!)

        let metas = try! portal.parseHTMLMeta(html: html)

        XCTAssertEqual(
            metas,
            [
                HTMLMeta(name: "charset", content: "utf-8"), // charset meta tag
                HTMLMeta(name: "X-UA-Compatible", content: "IE=edge"),
                HTMLMeta(name: "viewport", content: "width=device-width, initial-scale=1"),
                HTMLMeta(name: "csrf-param", content: "authenticity_token"),
                HTMLMeta(name: "csrf-token", content: "VeEeyMqDgJjFAnlsaqRJX4tWERGS89qRhHPU2jetjTwpCkr_l4u-5SQdxB1mvXaRm67tMDwLQFKA6QOjEPGD2Q")
            ]
        )
    }

    func testParseOTPPageInputs() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)

        let html = try! String(contentsOf: Bundle.module.url(forResource: "MethodSelectionPage", withExtension: "html")!)

        let extractedHtml = try! portal.extractHTML(html: html, cssSelector: "form#totp-form")
        let inputs = try! portal.parseHTMLInput(html: extractedHtml)

        XCTAssertEqual(
            inputs,
            [
                HTMLInput(name: "utf8", type: .hidden, value: "✓"),
                HTMLInput(name: "authenticity_token", type: .hidden, value: "-sXIN3BuAlYSqBeHqvXL46jh_jA4z06hgfed9ymvtH6PawKonTII3Z_TpmORb2f7vgDx37Rk8jtBRTN1gA_MIA"),
                HTMLInput(name: "totp", type: .text, value: ""),
            ]
        )
    }

    func testOtpPageSubmitScriptValidation() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)

        let script = try! String(contentsOf: Bundle.module.url(forResource: "OtpPageSubmitScript", withExtension: "js")!)

        XCTAssertTrue(portal.validateSubmitScript(script: script))
    }

    func testResourceListPageValidation() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)

        let html = try! String(contentsOf: Bundle.module.url(forResource: "ResourceListPage", withExtension: "html")!)

        XCTAssertTrue(try! portal.validateResourceListPage(html: html))
    }

    func testWaitingPageValidation() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)

        let html = try! String(contentsOf: Bundle.module.url(forResource: "WaitingPage", withExtension: "html")!)

        XCTAssertTrue(try! portal.validateWaitingPage(html: html))
    }
}
