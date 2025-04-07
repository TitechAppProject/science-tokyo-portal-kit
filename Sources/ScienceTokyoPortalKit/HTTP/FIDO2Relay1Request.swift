import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct FIDO2Relay1Request: HTTPRequest {
    let url: URL = URL(string: BaseURL.origin + "/idm/user/fido2_setting/add/relay1")!

    var method: HTTPMethod = .post
    
    var postContentType: PostContentType = .json

    var headerFields: [String: String]? = [
        "Referer": BaseURL.origin + "/idm/user/fido2_setting/",
        "Host": BaseURL.host,
        "Origin": BaseURL.origin,
        "Connection": "keep-alive",
        "Accept": "application/json",
        "Accept-Encoding": "br, gzip, deflate",
        "Accept-Language": "ja",
        "Sec-Fetch-Dest": "empty",
        "Sec-Fetch-Mode": "cors",
        "Sec-Fetch-Site": "same-origin",
        "Priority": "u=3, i",
        "Content-Type": "application/json;charset=UTF-8"
    ]

    var body: [String: String]? = nil
    
    var jsonBody: [String: Any]?

    init(htmlMetas: [HTMLMeta]) {
        // headerFieldsにhtmlMetasを追加
        htmlMetas.forEach {
            headerFields?[$0.name] = $0.content
        }
        jsonBody = [
            "siteId": "EXTIC",
            "svcId": "ISCT",
            "origin": "https://isct.ex-tic.com",
            "user": [
                "name": "ukai5605"
            ],
            "rp": [
                "id": "isct.ex-tic.com"
            ],
            "authnrAttachment": "",
            "credentialAlias": "TitechApp",
            "reqProtocolType": "1"
        ] // JSON文字列に変換
    }
}
