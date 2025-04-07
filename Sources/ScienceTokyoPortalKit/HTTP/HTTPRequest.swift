import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

enum BaseURL {
    static let origin = "https://isct.ex-tic.com"
    static let host = "isct.ex-tic.com"
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

enum PostContentType: String {
    case form = "application/x-www-form-urlencoded"
    case json = "application/json"
}

protocol HTTPRequest {
    var url: URL { get }

    var method: HTTPMethod { get }
    
    var postContentType: PostContentType { get }

    var headerFields: [String: String]? { get }

    var body: [String: String]? { get }
    
    var jsonBody: [String: Any]? { get }
}

extension HTTPRequest {
    var postContentType: PostContentType {
        .form
    }
    var jsonBody: [String: Any]? {
        nil
    }
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
            switch postContentType {
            case .form:
                components.queryItems = body?.map {
                    URLQueryItem(name: String($0), value: String($1).addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)?.replacingOccurrences(of: " ", with: "+") ?? "")
                }
                request.httpBody = (components.query ?? "").data(using: .utf8)
            case .json:
                request.httpBody = try? JSONSerialization.data(withJSONObject: jsonBody ?? [:], options: [.withoutEscapingSlashes])
            }
            request.allHTTPHeaderFields = headerFields?.merging(["User-Agent": userAgent], uniquingKeysWith: { key1, _ in key1 }) ?? [:]
            return request
        }
    }
        
}
