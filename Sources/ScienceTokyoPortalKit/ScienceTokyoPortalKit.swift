import Foundation
import Kanna

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum ScienceTokyoPortalLoginError: Error, Equatable {
    case invalidUserNamePage
    case invalidPasswordPage
    case invalidMethodSelectionPage
    case invalidEmailPage
    case invalidTOTPPage
    case invalidFIDO2Page
    case invalidWaitingPage
    case invalidResourceListPage
    case invalidEmailSending
    case invalidLMSPage
    
    case alreadyLoggedin
}

public struct ScienceTokyoPortal {
    private let httpClient: HTTPClient
    public static let defaultUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1"
    
    public init(urlSession: URLSession, userAgent: String = ScienceTokyoPortal.defaultUserAgent) {
        self.httpClient = HTTPClientImpl(urlSession: urlSession, userAgent: userAgent)
    }
    
    /// TitechPortalにログイン
    /// - Parameter account: ログイン情報
    public func loginCommon(account: ScienceTokyoPortalAccount) async throws -> String {
        /// ユーザー名ページの取得
        let userNamePageHtml = try await fetchUserNamePage()
        /// ユーザー名ページのバリデーション
        if try validateResourceListPage(html: userNamePageHtml){
            throw ScienceTokyoPortalLoginError.alreadyLoggedin
        }
        /// ユーザー名ページのバリデーション
        guard try validateUserNamePage(html: userNamePageHtml) else {
            throw ScienceTokyoPortalLoginError.invalidUserNamePage
        }
        /// Metaタグの取得
        let userNamePageMetas = try parseHTMLMeta(html: userNamePageHtml)
        /// 一部のHTMLを取り出す
        let extractedUserNameHtml = try extractHTML(html: userNamePageHtml, cssSelector: "div#identifier-field-wrapper")
        /// Inputタグの取得
        let userNamePageInputs = try parseHTMLInput(html: extractedUserNameHtml)
        
        /// ユーザー名Formの送信
        let userNamePageSubmitJson = try await submitUserName(htmlInputs: userNamePageInputs, htmlMetas: userNamePageMetas, username: account.username)
        /// ユーザー名ページsubmisionのバリデーション
        guard try validateUserNamePageSubmitJson(json: userNamePageSubmitJson, account: account) else {
            throw ScienceTokyoPortalLoginError.invalidUserNamePage
        }
        
        /// 一部のHTMLを取り出す
        let extractedPasswordPageHtml = try extractHTML(html: userNamePageHtml, cssSelector: "form#login")
        /// Inputタグの取得
        let passwordPageInputs = try parseHTMLInput(html: extractedPasswordPageHtml)
        /// PasswordFormの送信
        let passwordPageSubmitScript = try await submitPassword(htmlInputs: passwordPageInputs, htmlMetas: userNamePageMetas, username: account.username, password: account.password)
        guard validateSubmitScript(script: passwordPageSubmitScript) else {
            throw ScienceTokyoPortalLoginError.invalidPasswordPage
        }
        /// 認証方法選択ページの取得
        let methodSelectionPageHtml = try await fetchAuthorizationMethodSelectionPage()
        /// 認証方法選択ページのバリデーション
        guard try validateMethodSelectionPage(html: methodSelectionPageHtml) else {
            throw ScienceTokyoPortalLoginError.invalidMethodSelectionPage
        }
        return methodSelectionPageHtml
    }
    
    public func loginEmail(account: ScienceTokyoPortalAccount, methodSelectionPageHtml: String) async throws -> ([HTMLInput],[HTMLMeta]) {
        /// Metaタグの取得
        let methodSelectionPageMetas = try parseHTMLMeta(html: methodSelectionPageHtml)
        let emailSendingResult = try await submitEmailSending(htmlMetas: methodSelectionPageMetas)
        guard validateEmailSending(result: emailSendingResult) else {
            throw ScienceTokyoPortalLoginError.invalidEmailSending
        }
        /// 一部のHTMLを取り出す
        let extractedOTPPageHtml = try extractHTML(html: methodSelectionPageHtml, cssSelector: "form#emailotp-form")
        /// Inputタグの取得
        let otpPageInputs = try parseHTMLInput(html: extractedOTPPageHtml)
        return (otpPageInputs, methodSelectionPageMetas)
    }
    
    public func loginTOTP(account: ScienceTokyoPortalAccount, methodSelectionPageHtml: String) async throws{
        /// Metaタグの取得
        let methodSelectionPageMetas = try parseHTMLMeta(html: methodSelectionPageHtml)
        /// 一部のHTMLを取り出す
        let extractedOTPPageHtml = try extractHTML(html: methodSelectionPageHtml, cssSelector: "form#totp-form")
        /// Inputタグの取得
        let otpPageInputs = try parseHTMLInput(html: extractedOTPPageHtml)
        let otpPageSubmitScript = try await submitTOTP(htmlInputs: otpPageInputs, htmlMetas: methodSelectionPageMetas, account: account)
        /// OTPページsubmisionのバリデーション
        guard validateSubmitScript(script: otpPageSubmitScript) else {
            throw ScienceTokyoPortalLoginError.invalidTOTPPage
        }
        
        let otpPageSubmitURL = try parseScriptToURL(script: otpPageSubmitScript)
        let waitingPageHtml = try await fetchWaitingPage(url: otpPageSubmitURL)
        guard try validateWaitingPage(html: waitingPageHtml) else {
            throw ScienceTokyoPortalLoginError.invalidWaitingPage
        }
        
        let waitingPageHtmlInputs = try parseHTMLInput(html: waitingPageHtml)

        let resourceListPageHtml = try await fetchResourceListPage(htmlInputs: waitingPageHtmlInputs, referer: otpPageSubmitURL)
        guard try validateResourceListPage(html: resourceListPageHtml) else {
            throw ScienceTokyoPortalLoginError.invalidResourceListPage
        }
        let lmsPageHtml = try await fetchLMSPage()
        print("lmsPageHtml:", lmsPageHtml)
        guard validateLMSPage() else {
            throw ScienceTokyoPortalLoginError.invalidLMSPage
        }
        
        let lmsPageHtmlInputs = try parseHTMLInput(html: lmsPageHtml)
        let lmsRedirectPageHtml = try await fetchLMSRedirectPage(htmlInputs: lmsPageHtmlInputs)
        guard try validateLMSRedirectPage(html: lmsRedirectPageHtml) else {
            throw ScienceTokyoPortalLoginError.invalidLMSPage
        }
    }
    
    public func latterEmailLogin(htmlInputs: [HTMLInput], htmlMetas: [HTMLMeta], otp: String) async throws {
        let otpPageSubmitScript = try await submitEmail(htmlInputs: htmlInputs, htmlMetas: htmlMetas, otp: otp)
        /// OTPページsubmisionのバリデーション
        guard validateSubmitScript(script: otpPageSubmitScript) else {
            throw ScienceTokyoPortalLoginError.invalidEmailPage
        }
        let otpPageSubmitURL = try parseScriptToURL(script: otpPageSubmitScript)
        let waitingPageHtml = try await fetchWaitingPage(url: otpPageSubmitURL)
        guard try validateWaitingPage(html: waitingPageHtml) else {
            throw ScienceTokyoPortalLoginError.invalidWaitingPage
        }
        let waitingPageHtmlInputs = try parseHTMLInput(html: waitingPageHtml)
        print("waitingPageHtmlInputs:", waitingPageHtmlInputs)
        let resourceListPageHtml = try await fetchResourceListPage(htmlInputs: waitingPageHtmlInputs, referer: otpPageSubmitURL)
        guard try validateResourceListPage(html: resourceListPageHtml) else {
            throw ScienceTokyoPortalLoginError.invalidResourceListPage
        }
        let lmsPageHtml = try await fetchLMSPage()
        guard validateLMSPage() else {
            throw ScienceTokyoPortalLoginError.invalidLMSPage
        }
        
        let lmsPageHtmlInputs = try parseHTMLInput(html: lmsPageHtml)
        let lmsRedirectPageHtml = try await fetchLMSRedirectPage(htmlInputs: lmsPageHtmlInputs)
        guard try validateLMSRedirectPage(html: lmsRedirectPageHtml) else {
            throw ScienceTokyoPortalLoginError.invalidLMSPage
        }

    }
    
    public func setFIDO2() async throws {
        let fido2PageHtml = try await fetchFIDO2Page()
        print("fido2PageHtml:", fido2PageHtml)
        let fido2HtmlInput = try parseHTMLInput(html: fido2PageHtml)
        let fido2SettingsJson = try await submitFIDO2Settings(htmlInput: fido2HtmlInput)
        print("fido2SettingsJson:", fido2SettingsJson)
        let fido2Relay1Json = try await submitFIDO2Relay1(htmlInput: fido2HtmlInput)
        print("fido2RelayJson:", fido2Relay1Json)
        if let outputJSON = try createCredential(from: fido2Relay1Json) {
            print("生成された出力JSON:")
            print(outputJSON)
            let fido2Relay2Json = try await submitFIDO2Relay2(htmlInput: fido2HtmlInput, jsonBody: outputJSON)
            print("fido2Relay2Json:", fido2Relay2Json)
        } else {
            print("クレデンシャル生成に失敗しました")
        }
    }
    
    /// UsernameとPasswordのみが正しいかチェック
    /// - Parameter account: チェックするアカウント情報
    /// - Returns: 正しくログインできればtrue, エラーであればfalseを返す
    public func checkUsernamePassword(username: String, password: String) async throws -> Bool {
        let account = ScienceTokyoPortalAccount(username: username, password: password, totpSecret: nil)
        /// ユーザー名ページの取得
        let userNamePageHtml = try await fetchUserNamePage()
        /// ユーザー名ページのバリデーション
        if try validateResourceListPage(html: userNamePageHtml){
            throw ScienceTokyoPortalLoginError.alreadyLoggedin
        }
        /// ユーザー名ページのバリデーション
        guard try validateUserNamePage(html: userNamePageHtml) else {
            throw ScienceTokyoPortalLoginError.invalidUserNamePage
        }
        /// Metaタグの取得
        let userNamePageMetas = try parseHTMLMeta(html: userNamePageHtml)
        /// 一部のHTMLを取り出す
        let extractedUserNameHtml = try extractHTML(html: userNamePageHtml, cssSelector: "div#identifier-field-wrapper")
        /// Inputタグの取得
        let userNamePageInputs = try parseHTMLInput(html: extractedUserNameHtml)
        
        /// ユーザー名Formの送信
        let userNamePageSubmitJson = try await submitUserName(htmlInputs: userNamePageInputs, htmlMetas: userNamePageMetas, username: account.username)
        /// ユーザー名ページsubmisionのバリデーション
        guard try validateUserNamePageSubmitJson(json: userNamePageSubmitJson, account: account) else {
            throw ScienceTokyoPortalLoginError.invalidUserNamePage
        }
        
        /// 一部のHTMLを取り出す
        let extractedPasswordPageHtml = try extractHTML(html: userNamePageHtml, cssSelector: "form#login")
        /// Inputタグの取得
        let passwordPageInputs = try parseHTMLInput(html: extractedPasswordPageHtml)
        /// PasswordFormの送信
        let passwordPageSubmitScript = try await submitPassword(htmlInputs: passwordPageInputs, htmlMetas: userNamePageMetas, username: account.username, password: account.password)
        return validateSubmitScript(script: passwordPageSubmitScript)
    }


    
    private func fetchUserNamePage() async throws -> String {
        let request = UserNamePageRequest()
        
        return try await httpClient.send(request)
    }
    
    
    private func submitUserName(htmlInputs: [HTMLInput], htmlMetas: [HTMLMeta], username: String) async throws -> String {
        let htmlMetas = htmlMetas.filter{ $0.name == "csrf-token" }.map{ HTMLMeta(name: "X-CSRF-Token", content: $0.content )} // csrf-tokenを取り出す
        let htmlInputs = inject(htmlInputs, username: username, password: "")
        let request = UserNameSubmitRequest(htmlInputs: htmlInputs, htmlMetas: htmlMetas)
        
        return try await httpClient.send(request)
    }
    
    private func submitPassword(htmlInputs: [HTMLInput], htmlMetas: [HTMLMeta], username: String, password: String) async throws -> String {
        let htmlMetas = htmlMetas.filter{ $0.name == "csrf-token" }.map{ HTMLMeta(name: "X-CSRF-Token", content: $0.content )} // csrf-tokenを取り出す
        let injectedHtmlInputs = inject(htmlInputs, username: username, password: password)
        
        let request = PasswordSubmitRequest(htmlInputs: injectedHtmlInputs, htmlMetas: htmlMetas)
        
        return try await httpClient.send(request)
    }
    
    private func fetchAuthorizationMethodSelectionPage() async throws -> String {
        let request = AuthorizationMethodSelectionPageRequest()
        
        return try await httpClient.send(request)
    }
    
    private func submitEmailSending(htmlMetas: [HTMLMeta]) async throws -> String {
        let htmlMetas = htmlMetas.filter{ $0.name == "csrf-token" }.map{ HTMLMeta(name: "X-CSRF-Token", content: $0.content )} // csrf-tokenを取り出す
        let request = EmailSendingSubmitRequest(htmlMetas: htmlMetas)
        return try await httpClient.send(request)
    }
    
    private func submitEmail(htmlInputs: [HTMLInput], htmlMetas: [HTMLMeta], otp: String) async throws -> String {
        let htmlMetas = htmlMetas.filter{ $0.name == "csrf-token" }.map{ HTMLMeta(name: "X-CSRF-Token", content: $0.content )} // csrf-tokenを取り出す
        let injectedHtmlInputs = inject(htmlInputs, username: otp, password: "")
        let request = OTPSubmitRequest(htmlInputs: injectedHtmlInputs, htmlMetas: htmlMetas)
        return try await httpClient.send(request)
    }
    
    private func submitTOTP(htmlInputs: [HTMLInput], htmlMetas: [HTMLMeta], account: ScienceTokyoPortalAccount) async throws -> String {
        let htmlMetas = htmlMetas.filter{ $0.name == "csrf-token" }.map{ HTMLMeta(name: "X-CSRF-Token", content: $0.content )} // csrf-tokenを取り出す
        guard let accountTotp = account.totpSecret else {
            throw ScienceTokyoPortalLoginError.invalidUserNamePage
        }
        let otp = calculateTOTP(secret: accountTotp)
        let injectedHtmlInputs = inject(htmlInputs, username: otp, password: "")
        let request = OTPSubmitRequest(htmlInputs: injectedHtmlInputs, htmlMetas: htmlMetas)
        return try await httpClient.send(request)
    }
    
    private func fetchWaitingPage(url: String) async throws -> String {
        let request = WaitingPageRequest(url: URL(string: url)!)
        return try await httpClient.send(request)
    }
    
    private func fetchResourceListPage(htmlInputs: [HTMLInput], referer: String) async throws -> String {
        let request = ResourceListPageRequest(htmlInputs: htmlInputs, referer: referer)
        return try await httpClient.send(request)
    }
    
    private func fetchLMSPage() async throws -> String {
        let request = LMSPageRequest()
        return try await httpClient.send(request)
    }
        
    private func fetchLMSRedirectPage(htmlInputs: [HTMLInput]) async throws -> String {
        let request = LMSRedirectPageRequest(htmlInputs: htmlInputs, htmlMetas: [])
        return try await httpClient.send(request)
    }
        

    private func fetchFIDO2Page() async throws -> String {
        let request = FIDO2PageRequest()
        return try await httpClient.send(request)
    }
    
    private func submitFIDO2Settings(htmlInput: [HTMLInput]) async throws -> String {
        let htmlMetas = htmlInput.filter{ $0.name == "_csrf" }.map{ HTMLMeta(name: "x-csrf-token", content: $0.value )} // csrf-tokenを取り出す
        let request = FIDO2SettingsRequest(htmlMetas: htmlMetas)
        return try await httpClient.send(request)
    }
    
    private func submitFIDO2Relay1(htmlInput: [HTMLInput]) async throws -> String {
        let htmlMetas = htmlInput.filter{ $0.name == "_csrf" }.map{ HTMLMeta(name: "X-CSRF-Token", content: $0.value )} // csrf-tokenを取り出す
        let request = FIDO2Relay1Request(htmlMetas: htmlMetas)
        return try await httpClient.send(request)
    }
    
    private func submitFIDO2Relay2(htmlInput: [HTMLInput], jsonBody: [String: Any]) async throws -> String {
        let htmlMetas = htmlInput.filter{ $0.name == "_csrf" }.map{ HTMLMeta(name: "X-CSRF-Token", content: $0.value )} // csrf-tokenを取り出す
        let request = FIDO2Relay2Request(htmlMetas: htmlMetas, jsonBody: jsonBody)
        return try await httpClient.send(request)
    }
    
    private func validateUserNamePage(html: String) throws -> Bool {
        let doc = try HTML(html: html, encoding: .utf8)
        
        let bodyHtml = doc.css("body").first?.innerHTML ?? ""
        
        return bodyHtml.contains("Please set your e-mail address for password reissue to an e-mail other than m.isct.ac.jp.") || bodyHtml.contains("パスワード再発行用メールアドレスをm.isct.ac.jp以外のメールアドレスに忘れず必ず設定してください。")
    }
    
    private func validateUserNamePageSubmitJson(json: String, account: ScienceTokyoPortalAccount) throws -> Bool {
        let jsonObject = try JSONSerialization.jsonObject(with: Data(json.utf8), options: [])
        guard let jsonDict = jsonObject as? [String: Any] else {
            return false
        }
        guard let password = jsonDict["password"] as? Bool else {
            return false
        }
        guard let username = jsonDict["identifier"] as? String else {
            return false
        }
        return password && username == account.username
    }
        
    private func validateSubmitScript(script: String) -> Bool {
        return script.contains("window.location=")
    }
    
    private func validateMethodSelectionPage(html: String) throws -> Bool {
        let doc = try HTML(html: html, encoding: .utf8)
        
        let bodyHtml = doc.css("body").first?.innerHTML ?? ""
        
        return bodyHtml.contains("Please select an authentication method.") || bodyHtml.contains("認証方法を選択してください。")
    }

    private func validateWaitingPage(html: String) throws -> Bool {
        let doc = try HTML(html: html, encoding: .utf8)
        
        let bodyHtml = doc.css("body").first?.innerHTML ?? ""
        
        return bodyHtml.contains("Please wait for a moment") || bodyHtml.contains("しばらくお待ちください。")
    }
    
    private func validateResourceListPage(html: String) throws -> Bool {
        let doc = try HTML(html: html, encoding: .utf8)
        
        let bodyHtml = doc.css("body").first?.innerHTML ?? ""
        
        return bodyHtml.contains("Account") || bodyHtml.contains("アカウント")
    }
    
    private func validateLMSPage() -> Bool {
        return httpClient.cookies().contains(where: { $0.name == "MoodleSession" })
    }
    
    private func validateLMSRedirectPage(html: String) throws -> Bool {
        let doc = try HTML(html: html, encoding: .utf8)
        
        let bodyHtml = doc.css("body").first?.innerHTML ?? ""
        
        return bodyHtml.contains("ダッシュボード") || bodyHtml.contains("Dashboard")
    }
    
    private func validateEmailSending(result: String) -> Bool {
        return result.contains("succeeded")
    }
    
    func extractHTML(html: String, cssSelector: String) throws -> String {
        let doc = try HTML(html: html, encoding: .utf8)
        return doc.body?.css(cssSelector).first?.innerHTML ?? ""
    }
    
    func parseHTMLInput(html: String) throws -> [HTMLInput] {
        let doc = try HTML(html: html, encoding: .utf8)
        
        return doc.css("input").map {
            HTMLInput(
                name: $0["name"] ?? "",
                type: HTMLInputType(rawValue: $0["type"] ?? "") ?? .text,
                value: $0["value"] ?? ""
            )
        }
    }
    
    func parseHTMLSelect(html: String) throws -> [HTMLSelect] {
        let doc = try HTML(html: html, encoding: .utf8)
        
        return doc.css("select").map {
            HTMLSelect(
                name: $0["name"] ?? "",
                values: $0.css("option").map { $0["value"] ?? "" }
            )
        }
    }
    
    func parseHTMLMeta(html: String) throws -> [HTMLMeta] {
        let doc = try HTML(html: html, encoding: .utf8)
        
        return doc.css("meta").map {
            HTMLMeta(
                name: $0["name"] ?? "",
                content: $0["content"] ?? ""
            )
        }
    }
    
    func parseScriptToURL(script: String) throws -> String {
        let components = script.components(separatedBy: "\"")
        return components[1]
    }
    
    func inject(_ inputs: [HTMLInput], username: String, password: String) -> [HTMLInput] {
        var inputs = inputs
        if let firstTextInput = inputs.first(where: { $0.type == .text })
        {
            inputs = inputs.map {
                if $0 == firstTextInput {
                    var newInput = $0
                    newInput.value = username
                    return newInput
                }
                return $0
            }
        }
        if let firstPasswordInput = inputs.first(where: { $0.type == .password })
        {
            inputs = inputs.map {
                if $0 == firstPasswordInput {
                    var newInput = $0
                    newInput.value = password
                    return newInput
                }
                return $0
            }
        }
        return inputs
    }
}
