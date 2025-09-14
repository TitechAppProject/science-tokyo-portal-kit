import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

enum BaseURL {
    static let origin = "https://isct.ex-tic.com"
    static let host = "isct.ex-tic.com"
}

enum LMSBaseURL {
    static let origin = "https://lms.s.isct.ac.jp/2025/"
    static let host = "lms.s.isct.ac.jp"
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

protocol HTTPRequest {
    var url: URL { get }

    var method: HTTPMethod { get }

    var headerFields: [String: String]? { get }

    var body: [String: String]? { get }
}

extension HTTPRequest {
    func generate(userAgent: String) -> URLRequest {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            fatalError("Unable to create URL components")
        }

        switch method {
        case .get:
            var request = URLRequest(url: url)
            request.httpMethod = method.rawValue
            request.httpShouldHandleCookies = true
            request.allHTTPHeaderFields = headerFields?.merging(["User-Agent": userAgent], uniquingKeysWith: { key1, _ in key1 }) ?? [:]
            return request
        case .post:
            guard let url = components.url else {
                fatalError("Could not get url")
            }

            let allowedCharacterSet = CharacterSet(charactersIn: "!'();:@&=+$,/?%#[]").inverted
            var request = URLRequest(url: url)
            request.httpMethod = method.rawValue
            request.httpShouldHandleCookies = true
            components.queryItems = body?.map {
                URLQueryItem(name: String($0), value: String($1).addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)?.replacingOccurrences(of: " ", with: "+") ?? "")
            }
            request.httpBody = (components.query ?? "").data(using: .utf8)
            request.allHTTPHeaderFields = headerFields?.merging(["User-Agent": userAgent], uniquingKeysWith: { key1, _ in key1 }) ?? [:]
            return request
        }
    }

}
