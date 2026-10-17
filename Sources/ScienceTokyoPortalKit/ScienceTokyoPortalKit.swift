import Foundation
import Kanna

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum ScienceTokyoPortalLoginError: Error, Equatable {
    case invalidUserNamePage
    case invalidPasswordPage
    case invalidMethodSelectionPage
    case invalidTOTPPage
    case invalidWaitingPage
    case invalidResourceListPage

    case invalidFIDO2Page
    case invalidFIDO2Settings
    case invalidFIDO2Relay1
    case invalidFIDO2Relay2
    case invalidFIDO2Credential
    case invalidFIDO2LoginOptions
    case invalidFIDO2Login

    case alreadyLoggedin
}

/// FIDO2ログインに必要な認証情報。
/// passkey登録 (setFIDO2) の戻り値として返され、ログイン (loginWithFIDO2) の引数として使う。
/// ライブラリはこの情報を保存せず、保存は利用側の責務とする。
public struct FIDO2Credential {
    /// 資格情報ID (base64url)。サーバーの allowCredentials と一致させる
    public let credentialId: String
    /// P-256秘密鍵 (生32バイト)
    public let privateKey: Data
    /// 登録時のRP ID。秘密鍵を使用できるドメインの範囲を固定する。
    public let rpId: String
    /// 登録したアカウント。allowCredentialsが省略された認証でも対応関係を検証するために使う。
    public let username: String?
    /// 登録時のBackup Eligibility。資格情報の保存・復元時にも維持する。
    public let isBackupEligible: Bool

    public init(credentialId: String, privateKey: Data, isBackupEligible: Bool = true, rpId: String? = nil, username: String? = nil) {
        self.credentialId = credentialId
        self.privateKey = privateKey
        self.isBackupEligible = isBackupEligible
        self.rpId = rpId ?? BaseURL.host
        self.username = username
    }
}

public enum LMSLoginError: Error, Equatable {
    case policy
    case invalidDashboardPage
    case parseHtml
    case parseUrlScheme(responseHTML: String, responseUrl: URL?)
    case parseToken(responseHTML: String, responseUrl: URL?)
}

public struct ScienceTokyoPortal {
    private let httpClient: HTTPClient
    public static let defaultUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1"

    public init(urlSession: URLSession, userAgent: String = ScienceTokyoPortal.defaultUserAgent) {
        self.httpClient = HTTPClientImpl(urlSession: urlSession, userAgent: userAgent)
    }

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    /// 接続先をモックサーバ (https://extic-mock.isct.app) に切り替える
    /// 開発時のテストアカウントによるログイン経路用。
    /// Extic SSO と LMS 双方を mock に向ける。
    /// 一度呼ぶとプロセス終了まで mock URL に向き続ける。
    public static func changeToMockServer() {
        BaseURL.changeToMockServer()
        LMSBaseURL.changeToMockServer()
    }

    /// ScienceTokyoPortalにログイン
    /// - Parameter account: ログイン情報
    public func login(account: ScienceTokyoPortalAccount) async throws {
        /// ユーザー名ページの取得
        let userNamePageHtml = try await fetchUserNamePage()
        /// ユーザー名ページのバリデーション(既にログインしている場合)
        if try validateResourceListPage(html: userNamePageHtml) {
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
        /// ユーザー名submisionのバリデーション
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
        /// Metaタグの取得
        let methodSelectionPageMetas = try parseHTMLMeta(html: methodSelectionPageHtml)
        /// 一部のHTMLを取り出す
        let extractedOTPPageHtml = try extractHTML(html: methodSelectionPageHtml, cssSelector: "form#totp-form")
        /// Inputタグの取得
        let otpPageInputs = try parseHTMLInput(html: extractedOTPPageHtml)
        /// TOTPを計算した上でリクエストを送信
        let otpPageSubmitScript = try await submitTOTP(htmlInputs: otpPageInputs, htmlMetas: methodSelectionPageMetas, account: account)
        /// OTPページsubmisionのバリデーション
        guard validateSubmitScript(script: otpPageSubmitScript) else {
            throw ScienceTokyoPortalLoginError.invalidTOTPPage
        }
        /// OTPページsubmisionのレスポンスからURLを取得
        let otpPageSubmitURL = try parseScriptToURL(script: otpPageSubmitScript)
        /// otpPageSubmitURLのURLを元に、待機ページを取得
        let waitingPageHtml = try await fetchWaitingPage(url: otpPageSubmitURL)
        /// 待機ページのバリデーション
        guard try validateWaitingPage(html: waitingPageHtml) else {
            throw ScienceTokyoPortalLoginError.invalidWaitingPage
        }
        /// Inputタグの取得
        let waitingPageHtmlInputs = try parseHTMLInput(html: waitingPageHtml)
        /// リソース一覧ページを取得
        let resourceListPageHtml = try await fetchResourceListPage(htmlInputs: waitingPageHtmlInputs, referer: otpPageSubmitURL)
        guard try validateResourceListPage(html: resourceListPageHtml) else {
            throw ScienceTokyoPortalLoginError.invalidResourceListPage
        }
    }

    /// ログイン済みのセッションを使ってFIDO2のセットアップを行う
    /// - Parameter account: ログイン情報
    /// - Parameter displayName: 認証器の表示名。同じアカウントで追加登録する場合は別の名前を指定する。
    /// - Returns: FIDO2ログインに必要な資格情報 (呼び出し側で保存する)
    public func setFIDO2(account: ScienceTokyoPortalAccount, displayName: String = "TitechApp") async throws -> FIDO2Credential {
        /// FIDO2設定ページの取得
        let fido2PageHtml = try await fetchFIDO2Page()
        /// FIDO2設定ページのバリデーション
        guard let csrfToken = try extractFIDO2SettingsCSRFToken(html: fido2PageHtml) else {
            throw ScienceTokyoPortalLoginError.invalidFIDO2Page
        }
        /// 設定用のリクエスト(relay前の準備)
        let fido2SettingsJson = try await submitFIDO2Settings(csrfToken: csrfToken, displayName: displayName)
        guard try validateFIDO2Settings(json: fido2SettingsJson) else {
            throw ScienceTokyoPortalLoginError.invalidFIDO2Settings
        }
        /// チャレンジを取得するrelay1
        let fido2Relay1Json = try await submitFIDO2Relay1(csrfToken: csrfToken, username: account.username, displayName: displayName)
        guard try validateFIDO2Relay1(json: fido2Relay1Json) else {
            throw ScienceTokyoPortalLoginError.invalidFIDO2Relay1
        }
        /// 鍵ペアの生成とWebAuthn登録のシミュレーション
        let privateKey = try Ecc.generatePrivateKey()
        guard let registration = try createCredential(from: fido2Relay1Json, username: account.username, privateKey: privateKey) else {
            throw ScienceTokyoPortalLoginError.invalidFIDO2Credential
        }
        /// 登録結果を送るrelay2
        let fido2Relay2Json = try await submitFIDO2Relay2(csrfToken: csrfToken, jsonBody: registration.json)
        guard try validateFIDO2Relay2(json: fido2Relay2Json) else {
            throw ScienceTokyoPortalLoginError.invalidFIDO2Relay2
        }
        return FIDO2Credential(credentialId: registration.credentialId, privateKey: privateKey, rpId: registration.rpId, username: account.username)
    }

    /// FIDO2 (パスワードレス認証) でScienceTokyoPortalにログインする
    /// - Parameters:
    ///   - account: ログイン情報 (パスワードやTOTPは不要)
    ///   - credential: setFIDO2で登録した資格情報
    public func loginWithFIDO2(account: ScienceTokyoPortalAccount, credential: FIDO2Credential) async throws {
        /// リダイレクト後のページURLを相対URLの解決に使う。
        let pageRequest = UserNamePageRequest()
        let pageResponse = try await httpClient.send(pageRequest)
        let userNamePageHtml = pageResponse.html
        let pageURL = pageResponse.responseUrl ?? pageRequest.url
        /// 既にログインしている場合
        if try validateResourceListPage(html: userNamePageHtml) {
            throw ScienceTokyoPortalLoginError.alreadyLoggedin
        }
        /// FIDO2フォームからCSRFトークンと送信先を取得
        guard let fido2Form = try parseFIDO2LoginForm(html: userNamePageHtml, pageURL: pageURL) else {
            throw ScienceTokyoPortalLoginError.invalidFIDO2Page
        }
        /// チャレンジを取得
        let fido2OptionsJson = try await fetchFIDO2LoginOptions(form: fido2Form, identifier: account.username)
        guard try validateFIDO2LoginOptions(json: fido2OptionsJson, origin: fido2Form.origin.value) else {
            throw ScienceTokyoPortalLoginError.invalidFIDO2LoginOptions
        }
        /// WebAuthn認証のシミュレーション
        guard let assertion = try createAssertion(from: fido2OptionsJson, credential: credential, origin: fido2Form.origin.value, username: account.username) else {
            throw ScienceTokyoPortalLoginError.invalidFIDO2Credential
        }
        /// 認証結果を送信 (待機ページが返る)
        let waitingPageHtml = try await submitFIDO2Login(form: fido2Form, identifier: account.username, assertion: assertion)
        /// 待機ページのバリデーション
        guard try validateWaitingPage(html: waitingPageHtml) else {
            throw ScienceTokyoPortalLoginError.invalidFIDO2Login
        }
        /// Inputタグの取得
        let waitingPageHtmlInputs = try parseHTMLInput(html: waitingPageHtml)
        /// リソース一覧ページを取得
        let resourceListPageHtml = try await fetchResourceListPage(htmlInputs: waitingPageHtmlInputs, referer: fido2Form.submitURL.absoluteString)
        guard try validateResourceListPage(html: resourceListPageHtml) else {
            throw ScienceTokyoPortalLoginError.invalidResourceListPage
        }
    }

    /// LMSDashboardにログイン
    public func getLMSDashboard() async throws {
        let lmsPageHtml = try await fetchLMSPage()
        guard validateLMSPage(cookies: httpClient.cookies()) else {
            throw LMSLoginError.invalidDashboardPage
        }

        let lmsPageHtmlInputs = try parseHTMLInput(html: lmsPageHtml)
        let lmsRedirectPageHtml = try await fetchLMSRedirectPage(htmlInputs: lmsPageHtmlInputs)
        guard try !detectPolicyError(html: lmsRedirectPageHtml) else {
            throw LMSLoginError.policy
        }
        guard try validateLMSRedirectPage(html: lmsRedirectPageHtml) else {
            throw LMSLoginError.invalidDashboardPage
        }
    }

    /// LMSのWSTokenを取得
    /// - Returns: WSToken
    public func getLMSToken() async throws -> String {
        let (lmsTokenHtml, responseUrl) = try await fetchLMSTokenPage()
        guard
            let doc = { () -> HTMLDocument? in
                do {
                    return try HTML(html: lmsTokenHtml, encoding: .utf8)
                } catch {
                    return nil
                }
            }()
        else {
            throw LMSLoginError.parseHtml
        }
        guard
            let launchapp = doc.css("a#launchapp").first,
            let href = launchapp["href"],
            let decodedData = Data(base64Encoded: href.replacingOccurrences(of: "moodlemobile://token=", with: "")),
            let decodedStr = String(data: decodedData, encoding: .utf8)
        else {
            throw LMSLoginError.parseUrlScheme(responseHTML: lmsTokenHtml, responseUrl: responseUrl)
        }

        let splitedToken = decodedStr.components(separatedBy: ":::")

        if splitedToken.count > 1 {
            return splitedToken[1]
        } else {
            throw LMSLoginError.parseToken(responseHTML: lmsTokenHtml, responseUrl: responseUrl)
        }
    }

    /// UsernameとPasswordのみが正しいかチェック
    /// - Parameter username: ユーザー名
    /// - Parameter password: パスワード
    /// - Returns: 正しくログインできればtrue, エラーであればfalseを返す
    public func checkUsernamePassword(username: String, password: String) async throws -> Bool {
        let account = ScienceTokyoPortalAccount(username: username, password: password, totpSecret: nil)
        /// ユーザー名ページの取得
        let userNamePageHtml = try await fetchUserNamePage()
        /// ユーザー名ページのバリデーション
        if try validateResourceListPage(html: userNamePageHtml) {
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
        /// ユーザー名submisionのバリデーション
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

    /// ユーザー名ページを取得
    /// - Returns: ユーザー名ページのHTML
    private func fetchUserNamePage() async throws -> String {
        let request = UserNamePageRequest()

        return try await httpClient.send(request).html
    }

    /// ユーザー名formを送信
    /// - Parameters:
    ///   - htmlInputs: ユーザー名ページのInputタグ
    ///   - htmlMetas: ユーザー名ページのMetaタグ
    ///   - username: ユーザー名
    /// - Returns: ユーザー名formの送信結果
    private func submitUserName(htmlInputs: [HTMLInput], htmlMetas: [HTMLMeta], username: String) async throws -> String {
        let htmlMetas = htmlMetas.filter { $0.name == "csrf-token" }.map { HTMLMeta(name: "X-CSRF-Token", content: $0.content) }  // csrf-tokenを取り出す
        let htmlInputs = inject(htmlInputs, username: username, password: "")
        let request = UserNameSubmitRequest(htmlInputs: htmlInputs, htmlMetas: htmlMetas)

        return try await httpClient.send(request).html
    }

    /// PasswordFormを送信
    /// - Parameters:
    ///   - htmlInputs: ユーザー名ページのInputタグ
    ///   - htmlMetas: ユーザー名ページのMetaタグ
    ///   - username: ユーザー名
    ///   - password: パスワード
    /// - Returns: PasswordFormの送信結果
    private func submitPassword(htmlInputs: [HTMLInput], htmlMetas: [HTMLMeta], username: String, password: String) async throws -> String {
        let htmlMetas = htmlMetas.filter { $0.name == "csrf-token" }.map { HTMLMeta(name: "X-CSRF-Token", content: $0.content) }  // csrf-tokenを取り出す
        let injectedHtmlInputs = inject(htmlInputs, username: username, password: password)

        let request = PasswordSubmitRequest(htmlInputs: injectedHtmlInputs, htmlMetas: htmlMetas)

        return try await httpClient.send(request).html
    }

    /// 認証方法選択ページを取得
    /// - Returns: 認証方法選択ページのHTML
    private func fetchAuthorizationMethodSelectionPage() async throws -> String {
        let request = AuthorizationMethodSelectionPageRequest()

        return try await httpClient.send(request).html
    }

    /// TOTPを送信
    /// - Parameters:
    ///   - htmlInputs: 認証方法選択ページのInputタグ
    ///   - htmlMetas: 認証方法選択ページのMetaタグ
    ///   - account: ログイン情報
    /// - Returns: OTPFormの送信結果
    private func submitTOTP(htmlInputs: [HTMLInput], htmlMetas: [HTMLMeta], account: ScienceTokyoPortalAccount) async throws -> String {
        let htmlMetas = htmlMetas.filter { $0.name == "csrf-token" }.map { HTMLMeta(name: "X-CSRF-Token", content: $0.content) }  // csrf-tokenを取り出す
        guard let accountTotp = account.totpSecret else {
            throw ScienceTokyoPortalLoginError.invalidUserNamePage
        }
        let otp = try calculateTOTP(secret: accountTotp, current: Date())
        let injectedHtmlInputs = inject(htmlInputs, username: otp, password: "")
        let request = OTPSubmitRequest(htmlInputs: injectedHtmlInputs, htmlMetas: htmlMetas)
        return try await httpClient.send(request).html
    }

    /// 待機ページを取得
    /// - Parameter url: 待機ページのURL
    /// - Returns: 待機ページのHTML
    private func fetchWaitingPage(url: String) async throws -> String {
        let request = WaitingPageRequest(url: URL(string: url)!)
        return try await httpClient.send(request).html
    }

    /// リソース一覧ページを取得
    /// - Parameters:
    ///   - htmlInputs: 待機ページのInputタグ
    ///   - referer: 待機ページのURL
    /// - Returns: リソース一覧ページのHTML
    private func fetchResourceListPage(htmlInputs: [HTMLInput], referer: String) async throws -> String {
        let request = ResourceListPageRequest(htmlInputs: htmlInputs, referer: referer)
        return try await httpClient.send(request).html
    }

    /// FIDO2設定ページを取得
    /// - Returns: FIDO2設定ページのHTML
    private func fetchFIDO2Page() async throws -> String {
        let request = FIDO2PageRequest()
        return try await httpClient.send(request).html
    }

    /// FIDO2設定を送信
    /// - Parameter csrfToken: 設定フォーム内のCSRFトークン
    /// - Returns: FIDO2設定の送信結果
    private func submitFIDO2Settings(csrfToken: String, displayName: String) async throws -> String {
        let request = FIDO2SettingsRequest(csrfToken: csrfToken, displayName: displayName)
        return try await httpClient.send(request).html
    }

    /// FIDO2 Relay(1回目)を送信
    /// - Parameters:
    ///   - csrfToken: 設定フォーム内のCSRFトークン
    ///   - username: ユーザー名
    /// - Returns: FIDO2 Relay1の送信結果
    private func submitFIDO2Relay1(csrfToken: String, username: String, displayName: String) async throws -> String {
        let request = FIDO2Relay1Request(csrfToken: csrfToken, username: username, displayName: displayName)
        return try await httpClient.send(request).html
    }

    /// FIDO2 Relay(2回目)を送信
    /// - Parameters:
    ///   - csrfToken: 設定フォーム内のCSRFトークン
    ///   - jsonBody: FIDO2 Relay1のレスポンスから計算したJSON
    /// - Returns: FIDO2 Relay2の送信結果
    private func submitFIDO2Relay2(csrfToken: String, jsonBody: [String: Any]) async throws -> String {
        let request = FIDO2Relay2Request(csrfToken: csrfToken, jsonBody: jsonBody)
        return try await httpClient.send(request).html
    }

    /// FIDO2ログイン用のチャレンジを取得
    /// - Parameter form: FIDO2フォームから取得した設定
    /// - Parameter identifier: ユーザー名
    /// - Returns: PublicKeyCredentialRequestOptionsのJSON
    private func fetchFIDO2LoginOptions(form: FIDO2LoginForm, identifier: String) async throws -> String {
        let request = FIDO2LoginOptionsRequest(form: form, identifier: identifier)
        return try await httpClient.send(request).html
    }

    /// FIDO2ログインの認証結果を送信
    /// - Parameters:
    ///   - form: FIDO2フォームから取得した設定
    ///   - identifier: ユーザー名
    ///   - assertion: アサーションのフォーム値
    /// - Returns: 待機ページのHTML
    private func submitFIDO2Login(form: FIDO2LoginForm, identifier: String, assertion: [String: String]) async throws -> String {
        let request = FIDO2LoginSubmitRequest(form: form, identifier: identifier, assertion: assertion)
        return try await httpClient.send(request).html
    }

    /// LMSページの取得(前半)
    /// ログイン後にLMSに初めてアクセスする際は、LMS→Extic→LMSの遷移を経てLMSへのアクセスが成功する。
    /// この関数はその前半部分を担う
    private func fetchLMSPage() async throws -> String {
        let request = LMSPageRequest()
        return try await httpClient.send(request).html
    }

    /// LMSページの取得(後半)
    /// ログイン後にLMSに初めてアクセスする際は、LMS→Extic→LMSの遷移を経てLMSへのアクセスが成功する。
    /// この関数はその後半部分を担う
    /// - Returns: LMSページのHTML
    private func fetchLMSRedirectPage(htmlInputs: [HTMLInput]) async throws -> String {
        let request = LMSRedirectPageRequest(htmlInputs: htmlInputs, htmlMetas: [])
        return try await httpClient.send(request).html
    }

    /// LMS wsTokenの取得
    /// - Returns: LMSTokenページのHTML
    private func fetchLMSTokenPage() async throws -> (String, URL?) {
        let request = LMSTokenRequest()
        return try await httpClient.send(request)
    }

    /// ユーザー名ページのバリデーション
    /// - Parameter html: ユーザー名ページのHTML
    /// - Returns: ユーザー名ページが正しい場合はtrue, エラーであればfalseを返す
    func validateUserNamePage(html: String) throws -> Bool {
        let doc = try HTML(html: html, encoding: .utf8)

        let bodyHtml = doc.css("body").first?.innerHTML ?? ""

        return bodyHtml.contains("Enter Science Tokyo ID (8 alphanumerics).")
            || bodyHtml.contains("Science Tokyo ID(英数字８文字)を入力してください。")
    }

    /// ユーザー名Formのsubmisionのバリデーション
    /// - Parameters:
    ///   - json: ユーザー名FormのsubmisionのJSON
    ///   - account: ログイン情報
    /// - Returns: ユーザー名Formのsubmisionが正しい場合はtrue, エラーであればfalseを返す
    /// Exticではこの段階では存在しないユーザー名を検知しないので、ユーザー名が間違っていても同じ応答を返す
    /// そのため、このコードでユーザー名の間違いを検出できない
    func validateUserNamePageSubmitJson(json: String, account: ScienceTokyoPortalAccount) throws -> Bool {
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

    /// PasswordFormのsubmisionのバリデーション
    /// - Parameter script: PasswordFormのsubmisionのscript
    /// - Returns: PasswordFormのsubmisionが正しい場合はtrue, エラーであればfalseを返す
    func validateSubmitScript(script: String) -> Bool {
        let regex = try! NSRegularExpression(pattern: "window\\.location\\s*=\\s*\"(.*)\"")
        return regex.firstMatch(in: script, options: [], range: NSRange(location: 0, length: script.utf16.count)) != nil
    }

    /// 認証方法選択ページのバリデーション
    /// - Parameter html: 認証方法選択ページのHTML
    /// - Returns: 認証方法選択ページが正しい場合はtrue, エラーであればfalseを返す
    /// - Note: 認証方法選択ページは、認証方法を選択するためのページであることを確認する
    func validateMethodSelectionPage(html: String) throws -> Bool {
        let doc = try HTML(html: html, encoding: .utf8)

        let bodyHtml = doc.css("body").first?.innerHTML ?? ""

        return bodyHtml.contains("Please select an authentication method.") || bodyHtml.contains("認証方法を選択してください。")
    }

    /// 待機ページのバリデーション
    /// - Parameter html: 待機ページのHTML
    /// - Returns: 待機ページが正しい場合はtrue, エラーであればfalseを返す
    func validateWaitingPage(html: String) throws -> Bool {
        let doc = try HTML(html: html, encoding: .utf8)
        let bodyHtml = doc.css("body").first?.innerHTML ?? ""

        return bodyHtml.contains("Please wait for a moment") || bodyHtml.contains("しばらくお待ちください。")
    }

    /// リソース一覧ページのバリデーション
    /// - Parameter html: リソース一覧ページのHTML
    /// - Returns: リソース一覧ページが正しい場合はtrue, エラーであればfalseを返す
    func validateResourceListPage(html: String) throws -> Bool {
        let doc = try HTML(html: html, encoding: .utf8)

        let bodyHtml = doc.css("body").first?.innerHTML ?? ""

        return bodyHtml.contains("Account") || bodyHtml.contains("アカウント")
    }

    /// FIDO2設定ページのバリデーション
    /// - Parameter html: FIDO2設定ページのHTML
    /// - Returns: FIDO2設定ページが正しい場合はtrue, エラーであればfalseを返す
    func validateFIDO2Page(html: String) throws -> Bool {
        try extractFIDO2SettingsCSRFToken(html: html) != nil
    }

    /// 認証器設定用のフィールドを持つフォーム内からトークンを取り出す。
    func extractFIDO2SettingsCSRFToken(html: String) throws -> String? {
        let doc = try HTML(html: html, encoding: .utf8)
        let forms = doc.css("form").filter {
            $0.css("input[name='editDisplayName']").first != nil && $0.css("input[name='editRemarks']").first != nil
        }
        guard forms.count == 1,
            let token = forms.first?.css("input[name='_csrf']").first?["value"], !token.isEmpty
        else {
            return nil
        }
        return token
    }

    /// FIDO2設定のバリデーション
    /// - Parameter json: FIDO2設定の送信結果
    /// - Returns: FIDO2設定が正しい場合はtrue, エラーであればfalseを返す
    func validateFIDO2Settings(json: String) throws -> Bool {
        guard
            let data = json.data(using: .utf8),
            let object = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        else {
            return false
        }
        return object["status"] as? Bool == true
    }

    /// FIDO2 Relay1のバリデーション
    /// - Parameter json: FIDO2 Relay1の送信結果
    /// - Returns: FIDO2 Relay1が正しい場合はtrue, エラーであればfalseを返す
    /// - Note: ONEPASS_FIDO_SUCCESS_CODE (=1200) とresult(チャレンジJSON文字列)の有無を確認する
    func validateFIDO2Relay1(json: String) throws -> Bool {
        guard
            let data = json.data(using: .utf8),
            let object = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        else {
            return false
        }
        return (object["statusCode"] as? Int) == ExticFIDO2Protocol.successCode && object["result"] is String
    }

    /// FIDO2 Relay2のバリデーション
    /// - Parameter json: FIDO2 Relay2の送信結果
    /// - Returns: FIDO2 Relay2が正しい場合はtrue, エラーであればfalseを返す
    /// - Note: ONEPASS_FIDO_SUCCESS_CODE (=1200) を確認する
    func validateFIDO2Relay2(json: String) throws -> Bool {
        guard
            let data = json.data(using: .utf8),
            let object = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        else {
            return false
        }
        return (object["statusCode"] as? Int) == ExticFIDO2Protocol.successCode
    }

    /// FIDO2ログイン用のチャレンジJSONのバリデーション
    /// - Parameter json: /auth/session/fido2/new のレスポンスJSON
    /// - Returns: 必須のchallengeと、省略可能なフィールドの型・RPスコープが正しければtrue
    func validateFIDO2LoginOptions(json: String, origin: String = BaseURL.origin) throws -> Bool {
        guard let url = URL(string: origin), let relyingOrigin = FIDO2Origin(url: url) else { return false }
        return FIDO2LoginOptions(json: json, origin: relyingOrigin) != nil
    }

    /// ユーザー名ページからFIDO2フォームのauthenticity_tokenを抽出する
    /// - Parameter html: ユーザー名ページのHTML
    /// - Returns: authenticity_token (見つからない場合はnil)
    func extractFIDO2AuthenticityToken(html: String) throws -> String? {
        let doc = try HTML(html: html, encoding: .utf8)
        guard let form = fido2LoginForm(in: doc),
            let token = form.css("input[name='authenticity_token']").first?["value"], !token.isEmpty
        else {
            return nil
        }
        return token
    }

    func parseFIDO2LoginForm(html: String, pageURL: URL) throws -> FIDO2LoginForm? {
        let doc = try HTML(html: html, encoding: .utf8)
        guard let element = fido2LoginForm(in: doc) else { return nil }
        return FIDO2LoginForm(element: element, pageURL: pageURL)
    }

    /// 表示用のIDではなく、FIDO2用の設定属性または送信フィールドでフォームを識別する。
    func fido2LoginForm(in doc: HTMLDocument) -> Kanna.XMLElement? {
        let fields = ["identifier", "credential_id", "client_data_json", "authenticator_data", "signature"]
        let forms = doc.css("form").filter { form in
            form["data-options-path"] != nil || fields.allSatisfy { form.css("input[name='\($0)']").first != nil }
        }
        // 複数候補がある場合は別のフォームのCSRFトークンを使わない。
        return forms.count == 1 ? forms.first : nil
    }

    /// LMSページへのリクエストのバリデーション
    /// - Parameter cookies: httpclientのcookie全体
    /// - Returns: Cookieの内容が正しい場合はtrue, エラーであればfalseを返す
    func validateLMSPage(cookies: [HTTPCookie]) -> Bool {
        return cookies.contains(where: { $0.name == "MoodleSession" })
    }

    /// ポリシーエラーの検出
    /// - Parameter html: LMS一覧ページのHTML
    /// - Returns: ポリシーエラーであればtrue, そうでなければfalseを返す
    func detectPolicyError(html: String) throws -> Bool {
        let doc = try HTML(html: html, encoding: .utf8)

        if let title = doc.title, title.contains("ポリシー") || title.contains("Policies") {
            return true
        }
        return false
    }

    /// LMSページのバリデーション
    /// - Parameter html: LMS一覧ページのHTML
    /// - Returns: LMS一覧ページが正しい場合はtrue, エラーであればfalseを返す
    func validateLMSRedirectPage(html: String) throws -> Bool {
        let doc = try HTML(html: html, encoding: .utf8)

        let bodyHtml = doc.css("body").first?.innerHTML ?? ""

        return bodyHtml.contains("ダッシュボード") || bodyHtml.contains("Dashboard")
    }

    /// HTMLから特定の部分を抽出する
    /// - Parameters:
    ///   - html: HTML
    ///   - cssSelector: CSSセレクタ
    /// - Returns: 抽出したHTML
    func extractHTML(html: String, cssSelector: String) throws -> String {
        let doc = try HTML(html: html, encoding: .utf8)
        return doc.body?.css(cssSelector).first?.innerHTML ?? ""
    }

    /// HTMLからInputタグを取得する
    /// - Parameter html: HTML
    /// - Returns: Inputタグの配列
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

    /// HTMLからSelectタグを取得する
    /// - Parameter html: HTML
    /// - Returns: Selectタグの配列
    func parseHTMLSelect(html: String) throws -> [HTMLSelect] {
        let doc = try HTML(html: html, encoding: .utf8)

        return doc.css("select").map {
            HTMLSelect(
                name: $0["name"] ?? "",
                values: $0.css("option").map { $0["value"] ?? "" }
            )
        }
    }

    /// HTMLからMetaタグを取得する
    /// - Parameter html: HTML
    /// - Returns: Metaタグの配列
    func parseHTMLMeta(html: String) throws -> [HTMLMeta] {
        let doc = try HTML(html: html, encoding: .utf8)

        return doc.css("meta").map {
            let name: String
            if let nameAttr = $0["name"] {
                name = nameAttr
            } else if let httpEquivAttr = $0["http-equiv"] {
                name = httpEquivAttr
            } else if $0["charset"] != nil {
                name = "charset"
            } else {
                name = ""
            }

            let content = $0["content"] ?? ($0["charset"] ?? "")
            return HTMLMeta(
                name: name,
                content: content
            )
        }
    }

    /// HTMLからScriptタグを取得する
    /// - Parameter html: HTML
    /// - Returns: Scriptタグの配列
    func parseScriptToURL(script: String) throws -> String {
        let components = script.components(separatedBy: "\"")
        return components[1]
    }

    /// HTMLInputの配列に値を注入する
    /// - Parameters:
    ///   - inputs: HTMLInputの配列
    ///   - username: ユーザー名
    ///   - password: パスワード
    /// - Returns: 値を注入したHTMLInputの配列
    func inject(_ inputs: [HTMLInput], username: String, password: String) -> [HTMLInput] {
        var inputs = inputs
        if let firstTextInput = inputs.first(where: { $0.type == .text }) {
            inputs = inputs.map {
                if $0 == firstTextInput {
                    var newInput = $0
                    newInput.value = username
                    return newInput
                }
                return $0
            }
        }
        if let firstPasswordInput = inputs.first(where: { $0.type == .password }) {
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
