import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct FIDO2Relay2Request: HTTPRequest {
    let url: URL = URL(string: BaseURL.origin + "/idm/user/fido2_setting/add/relay2")!

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

    init(htmlMetas: [HTMLMeta], jsonBody: [String: Any]) {
        // headerFieldsにhtmlMetasを追加
        htmlMetas.forEach {
            headerFields?[$0.name] = $0.content
        }
        self.jsonBody = jsonBody
    }
}
