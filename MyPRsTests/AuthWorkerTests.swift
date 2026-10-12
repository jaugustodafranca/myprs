import Foundation
@testable import MyPRs
import Testing

@Suite(.serialized) struct AuthWorkerTests {
    private let worker = AuthWorker(session: .authWorkerStub, baseURL: URL(string: "https://auth.test")!)

    @Test func exchangesCodeAndVerifierForToken() async throws {
        AuthWorkerStub.respond(status: 200, body: #"{"access_token":"gho_abc"}"#)

        let token = try await worker.exchange(code: "abc123", verifier: "the-verifier")

        #expect(token == "gho_abc")
        let request = try #require(AuthWorkerStub.lastRequest)
        #expect(request.url?.absoluteString == "https://auth.test/token")
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        let body = try JSONDecoder().decode([String: String].self, from: AuthWorkerStub.lastBody ?? Data())
        #expect(body == ["code": "abc123", "code_verifier": "the-verifier"])
    }

    @Test func surfacesWorkerError() async {
        AuthWorkerStub.respond(status: 400, body: #"{"error":"bad_verification_code"}"#)

        await #expect(throws: LoginError.denied("bad_verification_code")) {
            try await worker.exchange(code: "abc", verifier: "v")
        }
    }

    @Test func failsOnUnexpectedBody() async {
        AuthWorkerStub.respond(status: 502, body: "oops")

        await #expect(throws: LoginError.exchangeFailed) {
            try await worker.exchange(code: "abc", verifier: "v")
        }
    }

    @Test func revokesToken() async throws {
        AuthWorkerStub.respond(status: 204, body: "")

        await worker.revoke("gho_abc")

        let request = try #require(AuthWorkerStub.lastRequest)
        #expect(request.url?.absoluteString == "https://auth.test/revoke")
        let body = try JSONDecoder().decode([String: String].self, from: AuthWorkerStub.lastBody ?? Data())
        #expect(body == ["access_token": "gho_abc"])
    }
}

private final class AuthWorkerStub: URLProtocol {
    nonisolated(unsafe) private static var status = 200
    nonisolated(unsafe) private static var body = ""
    nonisolated(unsafe) static var lastRequest: URLRequest?
    nonisolated(unsafe) static var lastBody: Data?

    static func respond(status: Int, body: String) {
        self.status = status
        self.body = body
        lastRequest = nil
        lastBody = nil
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lastRequest = request
        Self.lastBody = request.httpBody ?? request.httpBodyStream.map(Self.read)
        let response = HTTPURLResponse(url: request.url!, statusCode: Self.status, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(Self.body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    // URLSession moves the body into a stream before it reaches a URLProtocol.
    private static func read(_ stream: InputStream) -> Data {
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 1024)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            guard count > 0 else { break }
            data.append(buffer, count: count)
        }
        return data
    }
}

private extension URLSession {
    static var authWorkerStub: URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [AuthWorkerStub.self]
        return URLSession(configuration: configuration)
    }
}
