import Testing
import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

@testable import ScienceTokyoPortalKit

struct ScienceTokyoPortalKitTests {
    @Test func validateUserNamePageの正常系テスト() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)

        let html = try! String(contentsOf: Bundle.module.url(forResource: "UserNamePage", withExtension: "html")!)

        #expect(try! portal.validateUserNamePage(html: html))
    }

    @Test func validateUserNamePageの異常系テスト() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)
        /// 存在しないページにアクセスしたときに返ってくるHTML
        let html = try! String(contentsOf: Bundle.module.url(forResource: "ErrorPage", withExtension: "html")!)

        #expect(try! !portal.validateUserNamePage(html: html))
    }

    @Test func userNamePageからMetaタグを正常に取得できるかテスト() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)

        let html = try! String(contentsOf: Bundle.module.url(forResource: "UserNamePage", withExtension: "html")!)

        let metas = try! portal.parseHTMLMeta(html: html)

        #expect(
            metas == [
                HTMLMeta(name: "charset", content: "utf-8"),
                HTMLMeta(name: "X-UA-Compatible", content: "IE=edge"),
                HTMLMeta(name: "viewport", content: "width=device-width, initial-scale=1"),
                HTMLMeta(name: "csrf-param", content: "authenticity_token"),
                HTMLMeta(name: "csrf-token", content: "MCBhQD3s41D_Sisw0w_tpE2sTYhULaKvmOW9LVohQSI8xXVGjvR2rc8z0rpRpG-mjFb1-YJ4v8i-T8DyHiPsLA")
            ]
        )
    }

    @Test func userNamePageからinputタグを正常に取得できるかテスト() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)

        let html = try! String(contentsOf: Bundle.module.url(forResource: "UserNamePage", withExtension: "html")!)

        let extractedHtml = try! portal.extractHTML(html: html, cssSelector: "div#identifier-field-wrapper")
        let inputs = try! portal.parseHTMLInput(html: extractedHtml)

        #expect(
            inputs == [
                HTMLInput(name: "identifier", type: .text, value: ""),
            ]
        )
    }

    @Test func validateUserNamePageSubmitJsonの正常系テスト() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)
        let account = ScienceTokyoPortalAccount(username: "abcd1234", password: "password", totpSecret: nil)

        let json = try! String(contentsOf: Bundle.module.url(forResource: "UserNamePageSubmit", withExtension: "json")!)

        #expect(try! portal.validateUserNamePageSubmitJson(json: json, account: account))
    }

    @Test func validateUserNamePageSubmitJsonの異常系テスト() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)
        let account = ScienceTokyoPortalAccount(username: "abcd1234", password: "password", totpSecret: nil)

        let json = try! String(contentsOf: Bundle.module.url(forResource: "UserNamePageSubmitError", withExtension: "json")!)

        #expect(try! !portal.validateUserNamePageSubmitJson(json: json, account: account))
    }

    @Test func passwordPageからinputタグを正常に取得できるかテスト() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)

        let html = try! String(contentsOf: Bundle.module.url(forResource: "UserNamePage", withExtension: "html")!)

        let extractedHtml = try! portal.extractHTML(html: html, cssSelector: "form#login")
        let inputs = try! portal.parseHTMLInput(html: extractedHtml)

        #expect(
            inputs == [
                HTMLInput(name: "utf8", type: .hidden, value: "✓"),
                HTMLInput(name: "authenticity_token", type: .hidden, value: "-ZZOqjVkdg1heh6dmdxsoUfrx6PIB04RslZIjk3EW79lq11bk7lhErp4seE34Bzy23959IC2DUVeUUA2FSMWhA"),
                HTMLInput(name: "identifier", type: .text, value: ""),
                HTMLInput(name: "password", type: .password, value: ""),
            ]
        )
    }

    @Test func passwordPageSubmitScriptを入力としたvalidateSubmitScriptの正常系テスト() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)

        let script = try! String(contentsOf: Bundle.module.url(forResource: "PasswordPageSubmitScript", withExtension: "js")!)

        #expect(portal.validateSubmitScript(script: script))
    }

    @Test func passwordPageSubmitScriptを入力としたvalidateSubmitScriptの異常系テスト() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)
        /// 401 Unauthorizedが返ってくるためscriptは空
        let script = ""

        #expect(!portal.validateSubmitScript(script: script))
    }

    @Test func validateMethodSelectionPageの正常系テスト() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)

        let html = try! String(contentsOf: Bundle.module.url(forResource: "MethodSelectionPage", withExtension: "html")!)

        #expect(try! portal.validateMethodSelectionPage(html: html))
    }

    @Test func validateMethodSelectionPageの異常系テスト() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)
        /// ユーザー名・パスワードの入力ページを経由せずにいきなりMethodSelectionPageにアクセスするとユーザー名ページにリダイレクトされる
        let html = try! String(contentsOf: Bundle.module.url(forResource: "UserNamePage", withExtension: "html")!)

        #expect(try! !portal.validateMethodSelectionPage(html: html))
    }

    @Test func methodSelectionPageからMetaタグを正常に取得できるかテスト() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)

        let html = try! String(contentsOf: Bundle.module.url(forResource: "MethodSelectionPage", withExtension: "html")!)

        let metas = try! portal.parseHTMLMeta(html: html)

        #expect(
            metas == [
                HTMLMeta(name: "charset", content: "utf-8"), // charset meta tag
                HTMLMeta(name: "X-UA-Compatible", content: "IE=edge"),
                HTMLMeta(name: "viewport", content: "width=device-width, initial-scale=1"),
                HTMLMeta(name: "csrf-param", content: "authenticity_token"),
                HTMLMeta(name: "csrf-token", content: "VeEeyMqDgJjFAnlsaqRJX4tWERGS89qRhHPU2jetjTwpCkr_l4u-5SQdxB1mvXaRm67tMDwLQFKA6QOjEPGD2Q")
            ]
        )
    }

    @Test func methodSelectionPageからinputタグを正常に取得できるかテスト() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)

        let html = try! String(contentsOf: Bundle.module.url(forResource: "MethodSelectionPage", withExtension: "html")!)

        let extractedHtml = try! portal.extractHTML(html: html, cssSelector: "form#totp-form")
        let inputs = try! portal.parseHTMLInput(html: extractedHtml)

        #expect(
            inputs == [
                HTMLInput(name: "utf8", type: .hidden, value: "✓"),
                HTMLInput(name: "authenticity_token", type: .hidden, value: "-sXIN3BuAlYSqBeHqvXL46jh_jA4z06hgfed9ymvtH6PawKonTII3Z_TpmORb2f7vgDx37Rk8jtBRTN1gA_MIA"),
                HTMLInput(name: "totp", type: .text, value: ""),
            ]
        )
    }

    @Test func otpPageSubmitScriptを入力としたvalidateSubmitScriptの正常系テスト() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)

        let script = try! String(contentsOf: Bundle.module.url(forResource: "OtpPageSubmitScript", withExtension: "js")!)

        #expect(portal.validateSubmitScript(script: script))
    }

    @Test func otpPageSubmitScriptを入力としたvalidateSubmitScriptの異常系テスト() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)
        /// 401 Unauthorizedが返ってくるためscriptは空
        let script = ""

        #expect(!portal.validateSubmitScript(script: script))
    }

    @Test func validateWaitingPageの正常系テスト() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)

        let html = try! String(contentsOf: Bundle.module.url(forResource: "WaitingPage", withExtension: "html")!)

        #expect(try! portal.validateWaitingPage(html: html))
    }

    @Test func validateWaitingPageの異常系テスト() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)
        /// ユーザー名・パスワードの入力ページを経由せずにいきなりvalidateWaitingPageにアクセスするとエラーページにリダイレクトされる
        let html = try! String(contentsOf: Bundle.module.url(forResource: "ErrorPage", withExtension: "html")!)

        #expect(try! !portal.validateWaitingPage(html: html))
    }

    @Test func validateResourceListPageの正常系テスト() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)

        let html = try! String(contentsOf: Bundle.module.url(forResource: "ResourceListPage", withExtension: "html")!)

        #expect(try! portal.validateResourceListPage(html: html))
    }

    @Test func validateResourceListPageの異常系テスト() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)

        let html = try! String(contentsOf: Bundle.module.url(forResource: "SystemErrorPage", withExtension: "html")!)

        #expect(try! !portal.validateResourceListPage(html: html))
    }

    @Test func validateLMSPageの正常系テスト() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)

        let successCookies = [
            HTTPCookie(properties: [.name: "MoodleSession", .value: "test", .path: "/", .domain: "lms.s.isct.ac.jp"])!
        ]

        #expect(portal.validateLMSPage(cookies: successCookies))
    }
    
    @Test func validateLMSPageの異常系テスト() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)

        let failureCookies = [
            HTTPCookie(properties: [.name: "OtherCookie", .value: "test", .path: "/", .domain: "lms.s.isct.ac.jp"])!
        ]

        #expect(!portal.validateLMSPage(cookies: failureCookies))
    }

    @Test func validateLMSRedirectPageの正常系テスト() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)

        let html = try! String(contentsOf: Bundle.module.url(forResource: "LmsRedirectPage", withExtension: "html")!)

        #expect(try! portal.validateLMSRedirectPage(html: html))
    }

    @Test func validateLMSRedirectPageの異常系テスト() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)

        let html = try! String(contentsOf: Bundle.module.url(forResource: "LMSErrorPage", withExtension: "html")!)

        #expect(try! !portal.validateLMSRedirectPage(html: html))
    }

    @Test func detectPolicyErrorの正常系テスト() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)
        let noErrorHtml = try! String(contentsOf: Bundle.module.url(forResource: "LmsPage", withExtension: "html")!)
        #expect(try !portal.detectPolicyError(html: noErrorHtml))
    }
    
    @Test func detectPolicyErrorの異常系テスト() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)
        // 本当のポリシーエラーを取得できていないため仮置き
        let errorHtml = """
        <html>
        <title>
            Policies
        </title>
        <body>
        </body>
        </html>
        """
        #expect(try portal.detectPolicyError(html: errorHtml))
    }
}
