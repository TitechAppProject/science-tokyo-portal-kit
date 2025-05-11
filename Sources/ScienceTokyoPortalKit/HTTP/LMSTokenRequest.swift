import Foundation
import Kanna

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum T2ScholaLoginError: Error, Equatable {
    case parseHtml
    case policy
    case parseUrlScheme(responseHTML: String, responseUrl: URL?)
    case parseToken(responseHTML: String, responseUrl: URL?)
}

struct LMSTokenRequest: HTTPRequest {
    let url: URL

    var method: HTTPMethod = .get

    var headerFields: [String: String]? = [
        "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1"
    ]

    var body: [String: String]? = nil

    init() {
        let queryParameters =
            [
                "service": "moodle_mobile_app",
                "passport": String(Double.random(in: 0...1000)),
                "urlscheme": "moodlemobile",
            ] as [String: String]
        url = URL(string: LMSBaseURL.origin + "admin/tool/mobile/launch.php?" + queryParameters.map { "\($0)=\($1)" }.joined(separator: "&"))!
    }
}
