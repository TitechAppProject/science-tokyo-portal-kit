import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct FIDO2LoginOptionsRequest: HTTPRequest {
    let url: URL

    var method: HTTPMethod = .get

    var headerFields: [String: String]? = [
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

    init(form: FIDO2LoginForm, identifier: String) {
        var components = URLComponents(url: form.optionsURL, resolvingAgainstBaseURL: true)!
        components.queryItems = (components.queryItems ?? []).filter { $0.name != "identifier" } + [URLQueryItem(name: "identifier", value: identifier)]
        url = components.url!
        headerFields?["Referer"] = form.pageURL.absoluteString
        headerFields?["Origin"] = form.origin.value
    }
}
