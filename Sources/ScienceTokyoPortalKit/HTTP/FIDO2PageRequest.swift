import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct FIDO2PageRequest: HTTPRequest {
    let url: URL = URL(
        string: BaseURL.origin + "/idm/user/fido2_setting/")!

    var method: HTTPMethod = .get

    var headerFields: [String: String]? = [
        "Connection": "keep-alive",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Encoding": "br, gzip, deflate",
        "Accept-Language": "ja-jp",
        "Priority": "u=0, i",
        "Referer": BaseURL.origin + "/idm/user/portal/",
        "Sec-Fetch-Dest": "document",
        "Sec-Fetch-Mode": "navigate",
        "Sec-Fetch-Site": "same-origin",
    ]

    var body: [String: String]? = nil
}

