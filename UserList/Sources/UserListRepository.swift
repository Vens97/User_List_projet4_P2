import Foundation

struct UserListRepository {

    private let executeDataRequest: (URLRequest) async throws -> (Data, URLResponse)

    init(
        executeDataRequest: @escaping (URLRequest) async throws -> (Data, URLResponse) = URLSession.shared.data(for:)
    ) {
        self.executeDataRequest = executeDataRequest
    }

        func fetchUsers(quantity: Int) async throws -> [User] {
        guard let url = URL(string: "https://randomuser.me/api/") else {
            throw URLError(.badURL)
        }

        let request = try URLRequest(
            url: url,
            method: .GET,
            parameters: [
                "results": quantity
            ]
        )

        let (data, _) = try await executeDataRequest(request)

        let response = try JSONDecoder().decode(UserListResponse.self, from: data)
        
        return response.results.map(User.init)
    }
}



extension URLRequest {
    enum HTTPMethod: String {
        case GET, POST, PUT, DELETE, PATCH
    }

    init(url: URL, method: HTTPMethod, parameters: [String: Any] = [:]) throws {
        self.init(url: url)
        self.httpMethod = method.rawValue
        if method == .GET {
            let urlComponents = NSURLComponents(url: url, resolvingAgainstBaseURL: false)
            urlComponents?.queryItems = parameters.map { key, value in
                URLQueryItem(name: key, value: "\(value)")
            }
            if let urlWithQuery = urlComponents?.url {
                self.url = urlWithQuery
            }
        } else {
            self.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        }
    }
}
