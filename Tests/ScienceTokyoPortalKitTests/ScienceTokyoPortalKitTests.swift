import Foundation
import Testing

@testable import ScienceTokyoPortalKit

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

#if canImport(CryptoKit)
import CryptoKit
#else
import Crypto
#endif

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
                HTMLMeta(name: "csrf-token", content: "pyZr_b_Fp9BLeYqBkp7QoeaAt_VZsF0fSz1JmQxW433FS4h8e8gC0ve0P8pDrKy_yTZpYH3dA0wzzLONVLvIGQ"),
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
                HTMLInput(name: "identifier", type: .text, value: "")
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
                HTMLInput(name: "authenticity_token", type: .hidden, value: "yYAaIZ55k-d7MWeXfMDKmDI5PAXQ6IKra7TtjWV7jYoVDbMpOkEgaOH9WNxZwg94BxJ1BxHALQVCr_e33zlq2g"),
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
                HTMLMeta(name: "charset", content: "utf-8"),  // charset meta tag
                HTMLMeta(name: "X-UA-Compatible", content: "IE=edge"),
                HTMLMeta(name: "viewport", content: "width=device-width, initial-scale=1"),
                HTMLMeta(name: "csrf-param", content: "authenticity_token"),
                HTMLMeta(name: "csrf-token", content: "VeEeyMqDgJjFAnlsaqRJX4tWERGS89qRhHPU2jetjTwpCkr_l4u-5SQdxB1mvXaRm67tMDwLQFKA6QOjEPGD2Q"),
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

    @Test func validateFIDO2Pageの正常系テスト() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)

        let html = try! String(contentsOf: Bundle.module.url(forResource: "FIDO2Page", withExtension: "html")!)

        #expect(try! portal.validateFIDO2Page(html: html))
    }

    @Test func validateFIDO2Pageの異常系テスト() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)

        let html = try! String(contentsOf: Bundle.module.url(forResource: "ErrorPage", withExtension: "html")!)

        #expect(try! !portal.validateFIDO2Page(html: html))
    }

    @Test func validateFIDO2Settingsの正常系テスト() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)

        #expect(try! portal.validateFIDO2Settings(json: #"{"status":true}"#))
    }

    @Test func validateFIDO2Settingsの異常系テスト() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)
        /// 表示名が重複している場合
        let json = #"{"status":false,"validateMsg":"表示名が重複しています。"}"#

        #expect(try! !portal.validateFIDO2Settings(json: json))
    }

    @Test func validateFIDO2Relay1の正常系テスト() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)

        let json = try! String(contentsOf: Bundle.module.url(forResource: "FIDO2Relay1Response", withExtension: "json")!)

        #expect(try! portal.validateFIDO2Relay1(json: json))
    }

    @Test func validateFIDO2Relay1の異常系テスト() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)
        /// エラー時はstatusCodeが1200以外でresultが無い
        let json = #"{"description":"SERVICE.ERROR.NO_REQ_FIDO_MSG","statusCode":145}"#

        #expect(try! !portal.validateFIDO2Relay1(json: json))
    }

    @Test func validateFIDO2Relay2の正常系テスト() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)

        let json = #"{"statusCode":1200,"result":"{\"credentialHashId\":\"test\"}"}"#

        #expect(try! portal.validateFIDO2Relay2(json: json))
    }

    @Test func validateFIDO2Relay2の異常系テスト() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)
        /// 登録失敗時はstatusCodeが1200以外
        let json = #"{"description":"SERVICE.ERROR.NO_REQ_FIDO_MSG","statusCode":145}"#

        #expect(try! !portal.validateFIDO2Relay2(json: json))
    }

    @Test func createCredentialの正常系テスト() throws {
        let json = try! String(contentsOf: Bundle.module.url(forResource: "FIDO2Relay1Response", withExtension: "json")!)
        let privateKey = try Ecc.generatePrivateKey()

        let registration = try createCredential(from: json, username: "abcd1234", privateKey: privateKey)

        #expect(registration != nil)
        guard let registration = registration else { return }
        let output = registration.json
        #expect(output["origin"] as? String == "https://isct.ex-tic.com")
        #expect((output["user"] as? [String: Any])?["name"] as? String == "abcd1234")
        #expect((output["rp"] as? [String: Any])?["id"] as? String == "isct.ex-tic.com")
        #expect(registration.credentialId == (output["credential"] as? [String: Any])?["id"] as? String)

        let credential = output["credential"] as? [String: Any]
        #expect(credential?["type"] as? String == "public-key")
        #expect(credential?["id"] as? String != nil)
        #expect(credential?["rawId"] as? String != nil)

        let response = credential?["response"] as? [String: Any]
        #expect(response?["clientDataJSON"] as? String != nil)
        #expect(response?["attestationObject"] as? String != nil)

        // clientDataJSONの中身の検証
        let clientDataJSON = response?["clientDataJSON"] as? String ?? ""
        let padded = clientDataJSON + String(repeating: "=", count: (4 - clientDataJSON.count % 4) % 4)
        let decoded = String(data: Data(base64Encoded: padded.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/"))!, encoding: .utf8)!
        #expect(decoded.contains("\"type\":\"webauthn.create\""))
        #expect(decoded.contains("\"challenge\":\"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\""))
        #expect(decoded.contains("isct.ex-tic.com"))
    }

    @Test func createCredentialのattestationObjectの構造テスト() throws {
        let json = try! String(contentsOf: Bundle.module.url(forResource: "FIDO2Relay1Response", withExtension: "json")!)
        let privateKey = try Ecc.generatePrivateKey()

        let registration = try createCredential(from: json, username: "abcd1234", privateKey: privateKey)
        guard let registration = registration else {
            #expect(false)
            return
        }
        let output = registration.json
        guard
            let credential = output["credential"] as? [String: Any],
            let response = credential["response"] as? [String: Any],
            let attestationObject = response["attestationObject"] as? String
        else {
            #expect(false)
            return
        }

        // attestationObjectをデコードしてauthDataの構造を確認
        let padded = attestationObject + String(repeating: "=", count: (4 - attestationObject.count % 4) % 4)
        let data = Data(base64Encoded: padded.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/"))!
        let bytes = [UInt8](data)

        // CBOR map: a3 63666d74 64 6e6f6e65 ... (fmt="none")
        #expect(Array(bytes.prefix(7)) == [0xa3, 0x63, 0x66, 0x6d, 0x74, 0x64, 0x6e])

        // authData (58 a4: byte string of length 164)
        guard let marker = bytes.firstIndex(of: 0x58) else {
            #expect(false)
            return
        }
        let authData = Array(bytes.suffix(from: marker + 2))
        #expect(authData.count == 164)

        // rpIdHash (先頭32byte) = SHA256("isct.ex-tic.com")
        let rpIdHash = Data(authData[0..<32])
        #expect(SHA256.hash(data: Data("isct.ex-tic.com".utf8)) == rpIdHash)

        // flags (UP|UV|BE|BS|AT = 0x5d)
        #expect(authData[32] == 0x5d)

        // AAGUID (37..<53) は "none" attestationのため全て0
        #expect(authData[37..<53].allSatisfy { $0 == 0 })

        // credentialId length (2byte) と credentialId
        let credIdLen = Int(authData[53]) << 8 | Int(authData[54])
        #expect(credIdLen == 32)

        // credential.idとauthData内のcredentialIdが一致する
        let credentialId = Data(authData[55..<55 + credIdLen])
        let idBytes = Data(base64urlDecodedData: credential["id"] as? String ?? "")
        #expect(credentialId == idBytes)
    }
}

extension Data {
    init?(base64urlDecodedData string: String) {
        let padded = string + String(repeating: "=", count: (4 - string.count % 4) % 4)
        guard let data = Data(base64Encoded: padded.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")) else {
            return nil
        }
        self = data
    }
}
