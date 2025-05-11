import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct WaitingPageRequest: HTTPRequest {
    let url: URL

    var method: HTTPMethod = .get

    var headerFields: [String: String]? = [
        "Referer": BaseURL.origin + "/auth/session/second_factor",
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

    init(url: URL) {
        self.url = url
    }
}
