import Foundation

extension URLRequest {
    init(
        url: URL,
        method: HTTPMethod,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil
    ) throws {
        // Vérifie si l'URL fournie est valide
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }

        // Initialise l'URLRequest avec l'URL fournie
        self.init(url: url)

        // Définit la méthode HTTP (GET, POST, PUT, DELETE, PATCH)
        httpMethod = method.rawValue

        // Encode les paramètres dans l'URL ou le corps de la requête selon la méthode HTTP
        if let parameters = parameters {
            switch method {
            case .GET:
                encodeParametersInURL(parameters, components: components)
            case .POST, .PUT, .DELETE, .PATCH:
                try encodeParametersInBody(parameters)
            }
        }

        // Ajoute les en-têtes personnalisés
        if let headers = headers {
            for (key, value) in headers {
                setValue(value, forHTTPHeaderField: key)
            }
        }
    }

    // Encode les paramètres dans l'URL pour les requêtes GET
    private mutating func encodeParametersInURL(
        _ parameters: [String: Any],
        components: URLComponents
    ) {
        var components = components
        components.queryItems = parameters
            .map { ($0, "\($1)") }
            .map { URLQueryItem(name: $0, value: $1) }
        url = components.url
    }

    // Encode les paramètres dans le corps de la requête pour les requêtes POST, PUT, DELETE, PATCH
    private mutating func encodeParametersInBody(
        _ parameters: [String: Any]
    ) throws {
        setValue("application/json", forHTTPHeaderField: "Content-Type")
        httpBody = try JSONSerialization.data(
            withJSONObject: parameters,
            options: .prettyPrinted
        )
    }
}
