/// Extic / Onepass固有の取り決め。WebAuthnの標準定数とは分けて管理する。
enum ExticFIDO2Protocol {
    // Science Tokyo向けの既存relay要求で使用するテナント設定。
    static let siteId = "EXTIC"
    static let serviceId = "ISCT"

    // OnepassFido2.exgen.js の requestService が指定する reqProtocolType。
    static let registrationProtocolType = "1"

    // 公開されている /idm/user/rs/js/fido2/OnepassFido2Const.js の ONEPASS_FIDO_SUCCESS_CODE。
    static let successCode = 1200
}
