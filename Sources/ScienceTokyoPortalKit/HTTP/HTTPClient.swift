import Foundation

#if canImport(os)
import os
#endif

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

protocol HTTPClient {
    func send(_ request: HTTPRequest) async throws -> (html: String, responseUrl: URL?)
    func statusCode(_ request: HTTPRequest) async throws -> Int
    func cookies() -> [HTTPCookie]
}

struct HTTPClientImpl: HTTPClient {
    private let urlSession: URLSession
    #if !canImport(FoundationNetworking)
    private let urlSessionDelegate: URLSessionTaskDelegate
    private let urlSessionDelegateWithoutRedirect: URLSessionTaskDelegate
    #endif
    private let userAgent: String

    init(urlSession: URLSession, userAgent: String) {
        self.urlSession = urlSession
        #if !canImport(FoundationNetworking)
        self.urlSessionDelegate = HTTPClientDelegate()
        self.urlSessionDelegateWithoutRedirect = HTTPClientDelegateWithoutRedirect()
        #endif
        self.userAgent = userAgent
    }

    func send(_ request: HTTPRequest) async throws -> (html: String, responseUrl: URL?) {
        #if canImport(FoundationNetworking)
        let (data, response): (Data, URLResponse) = try await withCheckedThrowingContinuation { continuation in
            urlSession.dataTask(with: request.generate(userAgent: userAgent)) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: (data ?? Data(), response!))
                }
            }.resume()
        }
        let httpResponse = response as? HTTPURLResponse
        #else
        let (data, response) = try await urlSession.data(
            for: request.generate(userAgent: userAgent),
            delegate: urlSessionDelegate
        )
        let httpResponse = response as? HTTPURLResponse
        #endif

        return (String(data: data, encoding: .utf8) ?? "", httpResponse?.url)
    }

    func statusCode(_ request: HTTPRequest) async throws -> Int {
        #if canImport(FoundationNetworking)
        let response: URLResponse = try await withCheckedThrowingContinuation { continuation in
            urlSession.dataTask(with: request.generate(userAgent: userAgent)) { _, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: response!)
                }
            }.resume()
        }
        #else
        let (_, response) = try await urlSession.data(
            for: request.generate(userAgent: userAgent),
            delegate: urlSessionDelegateWithoutRedirect
        )
        #endif

        return (response as? HTTPURLResponse)?.statusCode ?? 0
    }

    func cookies() -> [HTTPCookie] {
        let cookies = urlSession.configuration.httpCookieStorage?.cookies ?? []
        return cookies
    }
}

struct HTTPClientMock: HTTPClient {
    func send(_ request: HTTPRequest) async throws -> (html: String, responseUrl: URL?) {
        ("", nil)
    }

    func statusCode(_ request: HTTPRequest) async throws -> Int {
        0
    }

    func cookies() -> [HTTPCookie] {
        return []
    }
}

class HTTPClientDelegate: URLProtocol, URLSessionTaskDelegate {
    #if DEBUG && canImport(os)
    private let logger = Logger(subsystem: "app.titech.science-tokyo-portal-kit", category: "HTTPClientDelegate")
    #endif

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Swift.Void
    ) {
        #if DEBUG && canImport(os)
        logger.debug(
            """
            \(response.statusCode) \(task.currentRequest?.httpMethod ?? "") \(task.currentRequest?.url?.absoluteString ?? "")
              requestHeader: \(task.currentRequest?.allHTTPHeaderFields ?? [:])
              requestBody: \(String(data: task.originalRequest?.httpBody ?? Data(), encoding: .utf8) ?? "")
              responseHeader: \(response.allHeaderFields)
              redirect -> \(request.httpMethod ?? "") \(request.url?.absoluteString ?? "")
            """
        )
        #endif

        completionHandler(request)
    }

    func urlSession(_: URLSession, task: URLSessionTask, didFinishCollecting _: URLSessionTaskMetrics) {
        #if DEBUG && canImport(os)
        logger.debug(
            """
            \(task.currentRequest!.httpMethod!) \(task.currentRequest!.url!.absoluteString)
              requestHeader: \(task.currentRequest!.allHTTPHeaderFields ?? [:])
              requestBody: \(String(data: task.originalRequest!.httpBody ?? Data(), encoding: .utf8) ?? "")
            """
        )
        #endif
    }
}

class HTTPClientDelegateWithoutRedirect: URLProtocol, URLSessionTaskDelegate {
    #if DEBUG && canImport(os)
    private let logger = Logger(subsystem: "app.titech.science-tokyo-portal-kit", category: "HTTPClientDelegateWithoutRedirect")
    #endif

    func urlSession(
        _: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest _: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Swift.Void
    ) {
        #if DEBUG && canImport(os)
        logger.debug(
            """
            \(response.statusCode) \(task.currentRequest?.httpMethod ?? "") \(task.currentRequest?.url?.absoluteString ?? "")
              requestHeader: \(task.currentRequest?.allHTTPHeaderFields ?? [:])
              requestBody: \(String(data: task.originalRequest?.httpBody ?? Data(), encoding: .utf8) ?? "")
            """
        )
        #endif
        completionHandler(nil)
    }

    func urlSession(_: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        #if DEBUG && canImport(os)
        if metrics.redirectCount == 0 {
            logger.debug(
                """
                200 \(task.currentRequest?.httpMethod ?? "") \(task.currentRequest?.url?.absoluteString ?? "")
                  requestHeader: \(task.currentRequest?.allHTTPHeaderFields ?? [:])
                  requestBody: \(String(data: task.originalRequest?.httpBody ?? Data(), encoding: .utf8) ?? "")
                """
            )
        }
        #endif
    }
}
