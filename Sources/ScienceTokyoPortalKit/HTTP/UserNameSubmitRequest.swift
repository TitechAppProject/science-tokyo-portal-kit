import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct UserNameSubmitRequest: HTTPRequest {
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

    init(htmlInputs: [HTMLInput], htmlMetas: [HTMLMeta]) {
        var urlComponents = URLComponents(url: URL(string: BaseURL.origin + "/auth/session/first_factor")!, resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = htmlInputs.map {
            URLQueryItem(name: $0.name, value: $0.value)
        }
        url = urlComponents.url!
        // headerFieldsにhtmlMetasを追加
        htmlMetas.forEach {
            headerFields?[$0.name] = $0.content
        }
    }
}
