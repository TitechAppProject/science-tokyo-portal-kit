import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct FIDO2SettingsRequest: HTTPRequest {
    let url: URL = URL(string: BaseURL.origin + "/idm/user/fido2_setting/add/pre")!

    var method: HTTPMethod = .post
    
    var postContentType: PostContentType = .json
    
    var jsonBody: [String: Any]? = nil

    var headerFields: [String: String]? = [
        "Referer": BaseURL.origin + "/idm/user/fido2_setting/",
        "Host": BaseURL.host,
        "Origin": BaseURL.origin,
        "Connection": "keep-alive",
        "Accept": "*/*",
        "Accept-Encoding": "br, gzip, deflate",
        "Accept-Language": "ja",
        "Sec-Fetch-Dest": "empty",
        "Sec-Fetch-Mode": "cors",
        "Sec-Fetch-Site": "same-origin",
        "Priority": "u=3, i",
        "Content-Type": "application/json;charset=UTF-8"
    ]

    var body: [String: String]?

    init(htmlMetas: [HTMLMeta]) {
        // headerFieldsにhtmlMetasを追加
        htmlMetas.forEach {
            headerFields?[$0.name] = $0.content
        }
        jsonBody = ["displayName":"TitechApp","remarks":""] // JSON文字列に変換
    }
}
