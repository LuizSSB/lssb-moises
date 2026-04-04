import Alamofire
import Foundation

final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    static let requestIDHeader = "X-Mock-Network-ID"
    private nonisolated(unsafe) static var handlers: [String: @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)] = [:]
    private static let lock = NSLock()
    
    override class func canInit(with request: URLRequest) -> Bool {
        true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }
    
    override func startLoading() {
        guard
            let requestID = request.value(forHTTPHeaderField: Self.requestIDHeader),
            let handler = Self.handler(for: requestID)
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    override func stopLoading() {}

    static func register(
        handler: @escaping @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)
    ) -> String {
        let requestID = UUID().uuidString
        lock.lock()
        handlers[requestID] = handler
        lock.unlock()
        return requestID
    }

    private static func handler(for requestID: String) -> (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data))? {
        lock.lock()
        let handler = handlers[requestID]
        lock.unlock()
        return handler
    }

    static func reset() {
        lock.lock()
        handlers.removeAll()
        lock.unlock()
    }
}

private struct MockRequestInterceptor: RequestInterceptor {
    let requestID: String

    func adapt(
        _ urlRequest: URLRequest,
        for session: Session,
        completion: @escaping @Sendable (Result<URLRequest, any Error>) -> Void
    ) {
        var request = urlRequest
        request.setValue(requestID, forHTTPHeaderField: MockURLProtocol.requestIDHeader)
        completion(.success(request))
    }
}

enum MockNetwork {
    static func makeSession(
        handler: @escaping @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)
    ) -> Session {
        let requestID = MockURLProtocol.register(handler: handler)

        let configuration = URLSessionConfiguration.af.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil

        return Session(
            configuration: configuration,
            interceptor: MockRequestInterceptor(requestID: requestID)
        )
    }

    static func reset() {
        // Handlers are keyed per session, so global teardown would race with parallel tests.
    }
}
