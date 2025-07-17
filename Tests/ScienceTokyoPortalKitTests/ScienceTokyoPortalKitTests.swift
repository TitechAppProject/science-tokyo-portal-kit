import XCTest

@testable import ScienceTokyoPortalKit

final class ScienceTokyoPortalKitTests: XCTestCase {
    func testUserNamePageValidation() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)

        let html = try! String(contentsOf: Bundle.module.url(forResource: "UserNamePage", withExtension: "html")!)

        XCTAssertTrue(try! portal.validateUserNamePage(html: html))
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
