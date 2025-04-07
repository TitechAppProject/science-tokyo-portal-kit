import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct AuthorizationMethodSelectionPageRequest: HTTPRequest {
    let url: URL = URL(
        string: BaseURL.origin + "/auth/session/second_factor")!

    var method: HTTPMethod = .get

    var headerFields: [String: String]? = [
        "Connection": "keep-alive",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Encoding": "br, gzip, deflate",
        "Accept-Language": "ja-jp",
        "Referer": BaseURL.origin + "/auth/session",
        "Sec-Fetch-Dest": "document",
        "Sec-Fetch-Mode": "navigate",
        "Sec-Fetch-Site": "same-origin",
        "Priority": "u=0, i",
    ]

    var body: [String: String]? = nil
}
