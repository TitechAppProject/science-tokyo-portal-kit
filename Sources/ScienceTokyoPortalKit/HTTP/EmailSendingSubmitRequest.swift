import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct EmailSendingSubmitRequest: HTTPRequest {
    let url: URL = URL(string: BaseURL.origin + "/auth/session/emailotp")!

    var method: HTTPMethod = .post
    
    var postContentType: PostContentType = .form

    var headerFields: [String: String]? = [
        "Referer": BaseURL.origin + "/auth/session/second_factor",
        "Host": BaseURL.host,
        "Origin": BaseURL.origin,
        "Connection": "keep-alive",
        "Accept": "*/*",
        "Accept-Encoding": "br, gzip, deflate",
        "Accept-Language": "ja",
        "Sec-Fetch-Dest": "empty",
        "Sec-Fetch-Mode": "cors",
        "Sec-Fetch-Site": "same-origin",
        "X-Requested-With": "XMLHttpRequest",
        "Priority": "u=3, i"
    ]

    var body: [String: String]?

    init(htmlMetas: [HTMLMeta]) {
        // headerFieldsにhtmlMetasを追加
        htmlMetas.forEach {
            headerFields?[$0.name] = $0.content
        }
    }
}
