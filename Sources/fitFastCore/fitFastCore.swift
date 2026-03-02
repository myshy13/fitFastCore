import Foundation

// MARK: - InsecureSessionDelegate (for self-signed dev certificates)
final class InsecureSessionDelegate: NSObject, URLSessionDelegate, @unchecked Sendable {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        if let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

// MARK: - FitFastAPIClient Actor
@available(iOS 15.0, *)
public actor FitFastAPIClient {

    // MARK: Singleton
    public static let shared: FitFastAPIClient = {
        let insecureSession = URLSession(
            configuration: .default,
            delegate: InsecureSessionDelegate(),
            delegateQueue: nil
        )
        return FitFastAPIClient(
            baseURL: URL(string: "https://limehouse.local:8945")!,
            session: insecureSession
        )
    }()

    // MARK: Properties
    private let baseURL: URL
    private let session: URLSession
    private var authToken: String?
    private let decoder: JSONDecoder
    
    public func currentToken() -> String? {
        return authToken
    }

    // MARK: Init
    public init(baseURL: URL = URL(string: "https://limehouse.local:8945")!,
                session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = JSONDecoder()
    }

    // MARK: API Models
    private struct TokenResponse: Decodable { let token: String }
    private struct CreateUserBody: Encodable { let email: String; let name: String; let password: String }
    private struct CreateRunPostBody: Encodable { let name: String; let description: String; let distance: Double; let minutes: Int; let seconds: Int, timestamp: String }

    // MARK: - Public API

    /// Authenticate with Basic auth and store token internally
    public func authenticate(username: String, password: String) async throws {
        let credentials = "\(username):\(password)"
        guard let data = credentials.data(using: .utf8) else {
            throw URLError(.badURL)
        }
        let base64 = data.base64EncodedString()

        var request = URLRequest(url: self.baseURL.appendingPathComponent("api/getToken"))
        request.httpMethod = "GET"
        request.setValue("Basic \(base64)", forHTTPHeaderField: "Authorization")

        let (dataResp, response) = try await self.session.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }

        let tokenResponse = try self.decoder.decode(TokenResponse.self, from: dataResp)
        self.authToken = tokenResponse.token
    }

    /// Create a new user
    public func createUser(email: String, name: String, password: String) async throws -> URLResponse {
        var request = URLRequest(url: self.baseURL.appendingPathComponent("api/createUser"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = CreateUserBody(email: email, name: name, password: password)
        request.httpBody = try JSONEncoder().encode(body)

        let (dataResp, response) = try await self.session.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }

        let tokenResponse = try self.decoder.decode(TokenResponse.self, from: dataResp)
        self.authToken = tokenResponse.token
        
        return response
    }

    /// Fetch authenticated user's runs
    public func getRuns() async throws -> [Run] {
        guard let token = self.authToken else {
            throw URLError(.userAuthenticationRequired)
        }

        var request = URLRequest(url: self.baseURL.appendingPathComponent("api/getRuns"))
        request.httpMethod = "GET"
        request.setValue(token, forHTTPHeaderField: "Authorization")

        let (dataResp, response) = try await self.session.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }

        return try self.decoder.decode([Run].self, from: dataResp)
    }
    
    public func postRun(name: String, description: String, distance: Double, minutes: Int, seconds: Int) async throws -> Bool {
        var request = URLRequest(url: self.baseURL.appendingPathComponent("api/postRun"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let body = CreateRunPostBody(name: name, description: description, distance: distance, minutes: minutes, seconds: seconds, timestamp: formatter.string(from: Date()))
        request.httpBody = try JSONEncoder().encode(body)

        let (dataResp, response) = try await self.session.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }

        struct Status: Decodable { let success: Bool }
        if let status = try? JSONDecoder().decode(Status.self, from: dataResp) {
            return true
        }
        return true
    }

    /// Logout
    public func logout() {
        self.authToken = nil
    }
}
