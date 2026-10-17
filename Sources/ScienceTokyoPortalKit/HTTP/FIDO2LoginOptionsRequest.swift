import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct FIDO2LoginOptionsRequest: HTTPRequest {
    let url: URL

    var method: HTTPMethod = .get

    var headerFields: [String: String]? = [
        "Referer": BaseURL.origin + "/auth/session",
        "Host": BaseURL.host,
        "Origin": BaseURL.origin,
        "Connection": "keep-alive",
        "Accept": "application/json, text/javascript, */*; q=0.01",
        "Accept-Encoding": "br, gzip, deflate",
        "Accept-Language": "ja",
        "Sec-Fetch-Dest": "empty",
        "Sec-Fetch-Mode": "cors",
        "Sec-Fetch-Site": "same-origin",
        "X-Requested-With": "XMLHttpRequest",
        "Priority": "u=3, i",
    ]

    var body: [String: String]? = nil

    init(identifier: String) {
        var components = URLComponents(string: BaseURL.origin + "/auth/session/fido2/new")!
        components.queryItems = [URLQueryItem(name: "identifier", value: identifier)]
        url = components.url!
    }
}
