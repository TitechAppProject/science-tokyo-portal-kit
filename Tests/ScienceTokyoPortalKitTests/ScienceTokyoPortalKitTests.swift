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

    func testMethodSelectionPageValidation() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)

        let html = try! String(contentsOf: Bundle.module.url(forResource: "MethodSelectionPage", withExtension: "html")!)

        XCTAssertTrue(try! portal.validateMethodSelectionPage(html: html))
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
