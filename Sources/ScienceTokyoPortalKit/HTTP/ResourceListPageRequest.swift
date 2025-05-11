import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct ResourceListPageRequest: HTTPRequest {
    let url: URL = URL(string: BaseURL.origin + "/idm/user/login/saml2/sso/user-isct")!

    var method: HTTPMethod = .post

    var postContentType: PostContentType = .form

    var headerFields: [String: String]? = [
        "Host": BaseURL.host,
        "Origin": BaseURL.origin,
        "Connection": "keep-alive",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Encoding": "br, gzip, deflate",
        "Accept-Language": "ja",
        "Sec-Fetch-Dest": "document",
        "Sec-Fetch-Mode": "navigate",
        "Sec-Fetch-Site": "same-origin",
        "Priority": "u=3, i",
    ]

    var body: [String: String]? = nil

    init(htmlInputs: [HTMLInput], referer: String) {
        headerFields?["Referer"] = referer
        body = htmlInputs.reduce(into: [String: String]()) {
            $0[$1.name] = $1.value
        }
    }
}
