import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct FIDO2LoginSubmitRequest: HTTPRequest {
    let url: URL = URL(string: BaseURL.origin + "/auth/session/fido2")!

    var method: HTTPMethod = .post

    var headerFields: [String: String]? = [
        "Referer": BaseURL.origin + "/auth/session",
        "Host": BaseURL.host,
        "Origin": BaseURL.origin,
        "Connection": "keep-alive",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
        "Accept-Encoding": "br, gzip, deflate",
        "Accept-Language": "ja",
        "Sec-Fetch-Dest": "document",
        "Sec-Fetch-Mode": "cors",
        "Sec-Fetch-Site": "same-origin",
        "X-Requested-With": "XMLHttpRequest",
        "Priority": "u=3, i",
    ]

    var body: [String: String]?

    init(authenticityToken: String, identifier: String, assertion: [String: String]) {
        var body = [
            "utf8": "\u{2713}",
            "authenticity_token": authenticityToken,
            "identifier": identifier,
        ]
        for (key, value) in assertion {
            body[key] = value
        }
        self.body = body
    }
}
