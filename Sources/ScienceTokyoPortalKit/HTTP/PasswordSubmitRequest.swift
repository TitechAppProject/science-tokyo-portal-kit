import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct PasswordSubmitRequest: HTTPRequest {
    let url: URL = URL(string: BaseURL.origin + "/auth/session")!

    var method: HTTPMethod = .post

    var headerFields: [String: String]? = [
        "Referer": BaseURL.origin + "/auth/session",
        "Host": BaseURL.host,
        "Origin": BaseURL.origin,
        "Connection": "keep-alive",
        "Accept": "*/*;q=0.5, text/javascript, application/javascript, application/ecmascript, application/x-ecmascript",
        "Accept-Encoding": "br, gzip, deflate",
        "Accept-Language": "ja",
        "Sec-Fetch-Dest": "empty",
        "Sec-Fetch-Mode": "cors",
        "Sec-Fetch-Site": "same-origin",
        "X-Requested-With": "XMLHttpRequest",
        "Priority": "u=3, i",
    ]
    var body: [String: String]?

    var jsonBody: [String: Any]?

    init(htmlInputs: [HTMLInput], htmlMetas: [HTMLMeta]) {
        body = htmlInputs.reduce(into: [String: String]()) {
            $0[$1.name] = $1.value
        }
        // headerFieldsにhtmlMetasを追加
        htmlMetas.forEach {
            headerFields?[$0.name] = $0.content
        }
    }
}
