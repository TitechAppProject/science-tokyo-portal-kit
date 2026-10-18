import Foundation
import Testing

@testable import ScienceTokyoPortalKit

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct FIDO2FlowTests {
    @Test func setupUsesTheSettingsFormTokenAndChosenName() async throws {
        let settingsURL = try #require(Bundle.module.url(forResource: "FIDO2Page", withExtension: "html"))
        let settings = try String(contentsOf: settingsURL, encoding: .utf8).replacingOccurrences(of: "FIDO2", with: "Passkey")
        let otherForm = "<form><input name='_csrf' value='unrelated-token'></form>"
        let relayURL = try #require(Bundle.module.url(forResource: "FIDO2Relay1Response", withExtension: "json"))
        let relay = try String(contentsOf: relayURL, encoding: .utf8)
        let client = FIDO2ScriptedClient(responses: [
            (otherForm + settings + otherForm, nil), (#"{"status":true}"#, nil), (relay, nil), (#"{"statusCode":1200}"#, nil),
        ])
        let portal = ScienceTokyoPortal(httpClient: client)
        let account = ScienceTokyoPortalAccount(username: "abcd1234", password: "", totpSecret: nil)
        let credential = try await portal.setFIDO2(account: account, displayName: "SecondDevice")
        #expect(credential.username == "abcd1234")
        #expect(credential.rpId == BaseURL.host)
        #expect(client.requests.count == 4)
        for request in client.requests.dropFirst() {
            #expect(request.value(forHTTPHeaderField: "X-CSRF-Token") == "test-csrf-token")
        }
        let preData = try #require(client.requests[1].httpBody)
        let relayData = try #require(client.requests[2].httpBody)
        let preBody = try #require(JSONSerialization.jsonObject(with: preData) as? [String: Any])
        let relayBody = try #require(JSONSerialization.jsonObject(with: relayData) as? [String: Any])
        #expect(preBody["displayName"] as? String == "SecondDevice")
        #expect(relayBody["credentialAlias"] as? String == "SecondDevice")
    }

    @Test func settingsValidationUsesTheFormStructure() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)
        let form = "<form><input name='editDisplayName'><input name='editRemarks'><input name='_csrf' value='token'></form>"
        #expect(try portal.validateFIDO2Page(html: "<body>任意の表示文言\(form)</body>"))
        #expect(try !portal.validateFIDO2Page(html: "<body>FIDO2 service unavailable</body>"))
        #expect(try !portal.validateFIDO2Page(html: form.replacingOccurrences(of: "value='token'", with: "value=''")))
        #expect(try !portal.validateFIDO2Page(html: form + form))
    }

    @Test func displayNameValidationAcceptsHalfWidthAlphanumerics() {
        #expect(isValidFIDO2DisplayName("fido2check"))
        #expect(isValidFIDO2DisplayName("MacBookPro14"))
        #expect(isValidFIDO2DisplayName("A"))
        #expect(isValidFIDO2DisplayName("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"))
        #expect(isValidFIDO2DisplayName(String(repeating: "a", count: 100)))
    }

    @Test func displayNameValidationRejectsNonAlphanumericOrOversizedNames() {
        #expect(!isValidFIDO2DisplayName(""))
        #expect(!isValidFIDO2DisplayName("fido2-check"))
        #expect(!isValidFIDO2DisplayName("fido2 check"))
        #expect(!isValidFIDO2DisplayName("fido2.check"))
        #expect(!isValidFIDO2DisplayName("表示名"))
        #expect(!isValidFIDO2DisplayName("ｆｉｄｏ２"))  // 全角
        #expect(!isValidFIDO2DisplayName(String(repeating: "a", count: 101)))
    }

    @Test func registrationRejectsInvalidDisplayNameWithoutSendingRequests() async throws {
        let client = FIDO2ScriptedClient(responses: [])
        let portal = ScienceTokyoPortal(httpClient: client)
        let account = ScienceTokyoPortalAccount(username: "abcd1234", password: "", totpSecret: nil)
        for name in ["", "fido2-check", "表示名", String(repeating: "a", count: 101)] {
            await #expect(throws: ScienceTokyoPortalLoginError.invalidFIDO2DisplayName) {
                try await portal.setFIDO2(account: account, displayName: name)
            }
        }
        #expect(client.requests.isEmpty)
    }

    @Test func registrationDetectsDuplicateDisplayNameInSettingsPage() async throws {
        let row = "<tr id='authenticator-0'><td id='b-displayName-0'><span>test</span></td></tr>"
        let form = "<form><input name='editDisplayName'><input name='editRemarks'><input name='_csrf' value='token'></form>"
        let client = FIDO2ScriptedClient(responses: [("<body>\(form)\(row)</body>", nil)])
        let portal = ScienceTokyoPortal(httpClient: client)
        let account = ScienceTokyoPortalAccount(username: "abcd1234", password: "", totpSecret: nil)
        await #expect(throws: ScienceTokyoPortalLoginError.duplicateFIDO2DisplayName) {
            try await portal.setFIDO2(account: account, displayName: "test")
        }
        #expect(client.requests.count == 1)
    }

    @Test func registrationIgnoresOtherDisplayNameTableRows() async throws {
        let row = "<tr id='authenticator-1'><td id='b-displayName-1'><span>iPhone &amp; Mac</span></td></tr>"
        let form = "<form><input name='editDisplayName'><input name='editRemarks'><input name='_csrf' value='token'></form>"
        let relayURL = try #require(Bundle.module.url(forResource: "FIDO2Relay1Response", withExtension: "json"))
        let relay = try String(contentsOf: relayURL, encoding: .utf8)
        let client = FIDO2ScriptedClient(responses: [
            ("<body>\(form)\(row)</body>", nil), (#"{"status":true}"#, nil), (relay, nil), (#"{"statusCode":1200}"#, nil),
        ])
        let portal = ScienceTokyoPortal(httpClient: client)
        let account = ScienceTokyoPortalAccount(username: "abcd1234", password: "", totpSecret: nil)
        let credential = try await portal.setFIDO2(account: account, displayName: "NewDevice")
        #expect(credential.rpId == BaseURL.host)
        #expect(client.requests.count == 4)
    }

    @Test func settingsResponseClassifiesDisplayNameErrors() throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)

        func expect(_ json: String, _ expected: ScienceTokyoPortalLoginError) {
            do {
                try portal.evaluateFIDO2SettingsResponse(json: json)
                Issue.record("should throw \(expected) for \(json)")
            } catch let error as ScienceTokyoPortalLoginError {
                #expect(error == expected)
            } catch {
                Issue.record("unexpected error \(error)")
            }
        }

        // 日本語メッセージ
        expect(#"{"status":false,"validateMsg":"表示名が重複しています。"}"#, .duplicateFIDO2DisplayName)
        expect(#"{"status":false,"validateMsg":"表示名は半角英数で入力してください。"}"#, .invalidFIDO2DisplayName)
        // 英語メッセージ (Accept-Languageにより英語でも返る)
        expect(#"{"status":false,"validateMsg":"Duplicate display name."}"#, .duplicateFIDO2DisplayName)
        expect(#"{"status":false,"validateMsg":"The display name must be entered using single-byte alphanumeric characters."}"#, .invalidFIDO2DisplayName)
        // その他の失敗
        expect(#"{"status":false,"validateMsg":"別の理由です。"}"#, .invalidFIDO2Settings)
        expect(#"{"status":false,"validateMsg":"An unexpected error occurred."}"#, .invalidFIDO2Settings)

        // 成功レスポンスはエラーにならない
        try portal.evaluateFIDO2SettingsResponse(json: #"{"status":true}"#)
    }

    @Test func loginUsesAdvertisedEndpoints() async throws {
        let pageURL = try #require(URL(string: BaseURL.origin + "/auth/custom/session"))
        let htmlURL = try #require(Bundle.module.url(forResource: "UserNamePage", withExtension: "html"))
        let html = try String(contentsOf: htmlURL, encoding: .utf8)
            .replacingOccurrences(of: "Science Tokyo ID(英数字８文字)を入力してください。", with: "新しい案内文")
            .replacingOccurrences(of: "Enter Science Tokyo ID (8 alphanumerics).", with: "New instructions")
            .replacingOccurrences(of: "id=\"fido2-form\"", with: "id=\"passkey-login\"")
            .replacingOccurrences(of: "data-options-path=\"/auth/session/fido2/new\"", with: "data-options-path=\"../passkeys/options?version=2\"")
            .replacingOccurrences(of: "action=\"/auth/session/fido2\"", with: "action=\"../passkeys/finish\"")
        let optionsURL = try #require(Bundle.module.url(forResource: "FIDO2LoginOptions", withExtension: "json"))
        let options = try String(contentsOf: optionsURL, encoding: .utf8)
        let client = FIDO2ScriptedClient(responses: [
            (html, pageURL), (options, nil),
            ("<body>Please wait for a moment<input name='SAMLResponse' value='test'></body>", nil),
            ("<body>Account</body>", nil),
        ])
        let portal = ScienceTokyoPortal(httpClient: client)
        let credential = FIDO2Credential(credentialId: "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB", privateKey: try Ecc.generatePrivateKey())
        try await portal.loginWithFIDO2(account: ScienceTokyoPortalAccount(username: "abcd1234", password: "", totpSecret: nil), credential: credential)

        #expect(client.requests.count == 4)
        let optionsRequest = try #require(client.requests.dropFirst().first)
        #expect(optionsRequest.url?.path == "/auth/passkeys/options")
        let requestURL = try #require(optionsRequest.url)
        let query = try #require(URLComponents(url: requestURL, resolvingAgainstBaseURL: true)?.queryItems)
        #expect(query.contains(URLQueryItem(name: "version", value: "2")))
        #expect(query.contains(URLQueryItem(name: "identifier", value: "abcd1234")))
        #expect(optionsRequest.value(forHTTPHeaderField: "Referer") == pageURL.absoluteString)
        #expect(client.requests[2].url?.path == "/auth/passkeys/finish")
        #expect(client.requests[3].value(forHTTPHeaderField: "Referer") == BaseURL.origin + "/auth/passkeys/finish")
    }

    @Test(arguments: ["https://other.example/options", "//other.example/options", "http://isct.ex-tic.com/options", "https://user@isct.ex-tic.com/options"])
    func loginRejectsUntrustedEndpoints(endpoint: String) throws {
        let portal = ScienceTokyoPortal(urlSession: .shared)
        let pageURL = try #require(URL(string: "https://isct.ex-tic.com/auth/session"))
        for (action, options) in [(endpoint, "/options"), ("/submit", endpoint)] {
            let html = "<form method='post' action='\(action)' data-options-path='\(options)'><input name='authenticity_token' value='token'></form>"
            #expect(try portal.parseFIDO2LoginForm(html: html, pageURL: pageURL) == nil)
        }
    }
}

private final class FIDO2ScriptedClient: HTTPClient {
    let responses: [(html: String, responseUrl: URL?)]
    var requests: [URLRequest] = []

    init(responses: [(String, URL?)]) {
        self.responses = responses
    }

    func send(_ request: HTTPRequest) async throws -> (html: String, responseUrl: URL?) {
        let index = requests.count
        requests.append(request.generate(userAgent: "test"))
        guard index < responses.count else { throw ScienceTokyoPortalLoginError.invalidFIDO2Login }
        return responses[index]
    }

    func statusCode(_ request: HTTPRequest) async throws -> Int { 200 }
    func cookies() -> [HTTPCookie] { [] }
}
