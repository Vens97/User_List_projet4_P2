//
import XCTest
@testable import UserList

final class UserListRepositoryTests: XCTestCase {
    // Cas de test réussi
    func testFetchUsersSuccess() async throws {
        // Given
        let repository = UserListRepository(executeDataRequest: mockExecuteDataRequest)
        let quantity = 2
        
        // When
        let users = try await repository.fetchUsers(quantity: quantity)
        
        // Then
        XCTAssertEqual(users.count, quantity)
        XCTAssertEqual(users[0].name.first, "John")
        XCTAssertEqual(users[0].name.last, "Doe")
        XCTAssertEqual(users[0].dob.age, 31)
        XCTAssertEqual(users[0].picture.large, "https://example.com/large.jpg")
        
        XCTAssertEqual(users[1].name.first, "Jane")
        XCTAssertEqual(users[1].name.last, "Smith")
        XCTAssertEqual(users[1].dob.age, 26)
        XCTAssertEqual(users[1].picture.medium, "https://example.com/medium.jpg")
    }
    
    // Cas de test échoué : Réponse JSON invalide
    func testFetchUsersInvalidJSONResponse() async throws {
        // Given
        let invalidJSONData = "invalid JSON".data(using: .utf8)!
        let invalidJSONResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!

        let mockExecuteDataRequest: (URLRequest) async throws -> (Data, URLResponse) = { _ in
            return (invalidJSONData, invalidJSONResponse)
        }
        
        let repository = UserListRepository(executeDataRequest: mockExecuteDataRequest)
        
        // When
        do {
            _ = try await repository.fetchUsers(quantity: 2)
            XCTFail("Response should fail")
        } catch {
            // Then
            XCTAssertTrue(error is DecodingError)
        }
    }
    

    // Cas de test : Délai d'attente réseau
    func testFetchUsersNetworkTimeout() async throws {
        // Given
        let timeoutError = URLError(.timedOut)

        let mockExecuteDataRequest: (URLRequest) async throws -> (Data, URLResponse) = { _ in
            throw timeoutError
        }
        
        let repository = UserListRepository(executeDataRequest: mockExecuteDataRequest)
        
        // When
        do {
            _ = try await repository.fetchUsers(quantity: 2)
            XCTFail("Request should timeout")
        } catch {
            // Then
            XCTAssertEqual(error as? URLError, timeoutError)
        }
    }
    
    
  

    
    // Cas de test : Erreur de réseau
    func testFetchUsersNetworkError() async throws {
        // Given
        let networkError = URLError(.notConnectedToInternet)

        let mockExecuteDataRequest: (URLRequest) async throws -> (Data, URLResponse) = { _ in
            throw networkError
        }
        
        let repository = UserListRepository(executeDataRequest: mockExecuteDataRequest)
        
        // When
        do {
            _ = try await repository.fetchUsers(quantity: 2)
            XCTFail("Request should fail with network error")
        } catch {
            // Then
            XCTAssertEqual(error as? URLError, networkError)
        }
    }
}

func testFetchUsersEmptyResponse() async throws {
    // Given
    let emptyJSONData = "{}".data(using: .utf8)!
    let emptyJSONResponse = HTTPURLResponse(
        url: URL(string: "https://example.com")!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: nil
    )!

    let mockExecuteDataRequest: (URLRequest) async throws -> (Data, URLResponse) = { _ in
        return (emptyJSONData, emptyJSONResponse)
    }
    
    let repository = UserListRepository(executeDataRequest: mockExecuteDataRequest)
    
    // When
    let users = try await repository.fetchUsers(quantity: 2)
    
    // Then
    XCTAssertEqual(users.count, 0)
}



private extension UserListRepositoryTests {
    // Définir un mock pour executeDataRequest qui renvoie des données prédéfinies
    func mockExecuteDataRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        // Créer des données de test avec une réponse JSON d'exemple
        let sampleJSON = """
            {
                "results": [
                    {
                        "name": {
                            "title": "Mr",
                            "first": "John",
                            "last": "Doe"
                        },
                        "dob": {
                            "date": "1990-01-01",
                            "age": 31
                        },
                        "picture": {
                            "large": "https://example.com/large.jpg",
                            "medium": "https://example.com/medium.jpg",
                            "thumbnail": "https://example.com/thumbnail.jpg"
                        }
                    },
                    {
                        "name": {
                            "title": "Ms",
                            "first": "Jane",
                            "last": "Smith"
                        },
                        "dob": {
                            "date": "1995-02-15",
                            "age": 26
                        },
                        "picture": {
                            "large": "https://example.com/large.jpg",
                            "medium": "https://example.com/medium.jpg",
                            "thumbnail": "https://example.com/thumbnail.jpg"
                        }
                    }
                ]
            }
        """
        
        let data = sampleJSON.data(using: .utf8)!
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (data, response)
    }
}

