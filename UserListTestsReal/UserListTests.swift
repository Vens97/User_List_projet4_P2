import XCTest
@testable import UserList
import Combine

// Test ViewModel
final class UserListViewModelTests: XCTestCase {
    var viewModel: UserListViewModel!
    var repository: UserListRepositoryMock!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        repository = UserListRepositoryMock()
        viewModel = UserListViewModel(repository: repository)
        cancellables = []
    }

    override func tearDown() {
        viewModel = nil
        repository = nil
        cancellables = nil
        super.tearDown()
    }

    // Test succès de récupération des utilisateurs
    func testFetchUsersSuccess() async throws {
        // Given
        repository.mockUsers = [.mockUser1, .mockUser2]

        // When
        await viewModel.fetchUsers()

        // Then
        XCTAssertEqual(viewModel.users.count, 2)
        XCTAssertEqual(viewModel.users[0], .mockUser1)
        XCTAssertEqual(viewModel.users[1], .mockUser2)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    // Test réponse JSON invalide
    func testFetchUsersInvalidJSONResponse() async throws {
        // Given
        repository.shouldReturnInvalidJSON = true

        // When
        await viewModel.fetchUsers()

        // Then
        XCTAssertTrue(viewModel.users.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    // Test délai d'attente réseau
    func testFetchUsersNetworkTimeout() async throws {
        // Given
        repository.shouldReturnNetworkError = true
        repository.networkError = URLError(.timedOut)

        // When
        await viewModel.fetchUsers()

        // Then
        XCTAssertTrue(viewModel.users.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.errorMessage, URLError(.timedOut).localizedDescription)
    }

    // Test erreur réseau
    func testFetchUsersNetworkError() async throws {
        // Given
        repository.shouldReturnNetworkError = true
        repository.networkError = URLError(.notConnectedToInternet)

        // When
        await viewModel.fetchUsers()

        // Then
        XCTAssertTrue(viewModel.users.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.errorMessage, URLError(.notConnectedToInternet).localizedDescription)
    }

    // Test si plus de données doivent être chargées pour le dernier utilisateur
    func testShouldLoadMoreDataForLastUser() {
        // Given
        viewModel.users = [.mockUser1, .mockUser2]

        // When
        let shouldLoadMore = viewModel.shouldLoadMoreData(currentItem: .mockUser2)

        // Then
        XCTAssertTrue(shouldLoadMore, "shouldLoadMoreData doit être true pour le dernier utilisateur.")
    }

    // Test si plus de données ne doivent pas être chargées pour un utilisateur autre que le dernier
    func testShouldNotLoadMoreDataForNonLastUser() {
        // Given
        viewModel.users = [.mockUser1, .mockUser2]

        // When
        let shouldLoadMore = viewModel.shouldLoadMoreData(currentItem: .mockUser1)

        // Then
        XCTAssertFalse(shouldLoadMore, "shouldLoadMoreData doit être false pour un utilisateur autre que le dernier.")
    }

    func testFetchUsersSuccess3() async throws {
        // Given
        repository.mockUsers = [.mockUser1, .mockUser2]

        // When
        await viewModel.fetchUsers()

        // Then
        XCTAssertEqual(viewModel.users.count, 2, "La liste des utilisateurs devrait contenir 2 utilisateurs.")
        XCTAssertEqual(viewModel.users[0], .mockUser1, "Le premier utilisateur devrait être mockUser1.")
        XCTAssertEqual(viewModel.users[1], .mockUser2, "Le deuxième utilisateur devrait être mockUser2.")
        XCTAssertFalse(viewModel.isLoading, "Le chargement ne devrait pas être en cours après la récupération.")
        XCTAssertNil(viewModel.errorMessage, "Le message d'erreur doit être nil après la récupération.")
    }

    // Test de réinitialisation d'état avec une erreur de réseau
    func testReloadUsersHandlesNetworkError() async throws {
        // Given
        viewModel.users = [.mockUser1]
        repository.shouldReturnNetworkError = true
        repository.networkError = URLError(.notConnectedToInternet)

        // When
        await viewModel.reloadUsers()

        // Then
        XCTAssertTrue(viewModel.users.isEmpty, "La liste des utilisateurs doit être vide après le rechargement même en cas d'erreur réseau.")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.errorMessage, URLError(.notConnectedToInternet).localizedDescription)
    }

    func testShouldLoadMoreDataWithSingleUser() {
        // Given
        viewModel.users = [.mockUser1]

        // When
        let shouldLoadMore = viewModel.shouldLoadMoreData(currentItem: .mockUser1)

        // Then
        XCTAssertTrue(shouldLoadMore, "shouldLoadMoreData doit être true quand il n'y a qu'un utilisateur dans la liste.")
    }

    func testShouldNotLoadMoreDataWhenListIsEmpty() {
        // Given
        viewModel.users = []

        // When
        let shouldLoadMore = viewModel.shouldLoadMoreData(currentItem: .mockUser1)

        // Then
        XCTAssertFalse(shouldLoadMore, "shouldLoadMoreData doit être false si la liste est vide.")
    }

    func testFetchUsersAndReloadUsers() async throws {
        // Given
        repository.mockUsers = [.mockUser1, .mockUser2]
        
        // When
        await viewModel.fetchUsers()
        
        // Then
        XCTAssertEqual(viewModel.users.count, 2, "La liste des utilisateurs devrait contenir 2 utilisateurs.")
        XCTAssertEqual(viewModel.users[0], .mockUser1, "Le premier utilisateur devrait être mockUser1.")
        XCTAssertEqual(viewModel.users[1], .mockUser2, "Le deuxième utilisateur devrait être mockUser2.")
        XCTAssertFalse(viewModel.isLoading, "Le chargement ne devrait pas être en cours après la récupération.")
        XCTAssertNil(viewModel.errorMessage, "Le message d'erreur doit être nil après la récupération.")

        // When reloading users
        viewModel.users = [.mockUser1]
        repository.mockUsers = [.mockUser2]
        await viewModel.reloadUsers()

        // Then
        XCTAssertEqual(viewModel.users.count, 1, "La liste des utilisateurs devrait contenir 1 utilisateur après le rechargement.")
        XCTAssertEqual(viewModel.users[0], .mockUser2, "L'utilisateur après rechargement devrait être mockUser2.")
        XCTAssertFalse(viewModel.isLoading, "Le chargement ne devrait pas être en cours après le rechargement.")
        XCTAssertNil(viewModel.errorMessage, "Le message d'erreur doit être nil après le rechargement.")
    }

    // Test échec : Cas où une réponse JSON invalide est simulée
    func testFetchUsersInvalidJSON() async throws {
        let mockRepository = UserListRepositoryMock()
        mockRepository.shouldReturnInvalidJSON = true

        do {
            _ = try await mockRepository.fetchUsers(quantity: 1)
            XCTFail("Expected decoding error, but succeeded.")
        } catch {
            XCTAssertTrue(error is DecodingError)
        }
    }
}

// Mock repository pour les tests
class UserListRepositoryMock: UserListRepository {
    var mockUsers: [User] = []
    var shouldReturnInvalidJSON = false
    var shouldReturnNetworkError = false
    var networkError: URLError?

    override func fetchUsers(quantity: Int) async throws -> [User] {
        if shouldReturnInvalidJSON {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Invalid JSON"))
        }

        if shouldReturnNetworkError, let error = networkError {
            throw error
        }

        return mockUsers
    }
}

// Extensions pour créer des objets User mock
extension User {
    static var mockUser1: User {
        return User(
            name: Name(title: "Mr", first: "John", last: "Doe"),
            dob: Dob(date: "1990-01-01", age: 31),
            picture: Picture(
                large: "https://example.com/large.jpg",
                medium: "https://example.com/medium.jpg",
                thumbnail: "https://example.com/thumbnail.jpg"
            )
        )
    }

    static var mockUser2: User {
        return User(
            name: Name(title: "Ms", first: "Jane", last: "Smith"),
            dob: Dob(date: "1995-02-15", age: 26),
            picture: Picture(
                large: "https://example.com/large.jpg",
                medium: "https://example.com/medium.jpg",
                thumbnail: "https://example.com/thumbnail.jpg"
            )
        )
    }
}

// Définition des structures pour les objets User mock
struct User: Equatable {
    let name: Name
    let dob: Dob
    let picture: Picture

    struct Name: Equatable {
        let title: String
        let first: String
        let last: String
    }

    struct Dob: Equatable {
        let date: String
        let age: Int
    }

    struct Picture: Equatable {
        let large: String
        let medium: String
        let thumbnail: String
    }
}

// Définition du ViewModel
class UserListViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let repository: UserListRepository

    init(repository: UserListRepository) {
        self.repository = repository
    }

    func fetchUsers() async {
        isLoading = true
        errorMessage = nil
        do {
            let users = try await repository.fetchUsers(quantity: 10)
            self.users = users
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func reloadUsers() async {
        users.removeAll()
        await fetchUsers()
    }

    func shouldLoadMoreData(currentItem: User) -> Bool {
        return users.last == currentItem
    }
}

// Repository de base pour les tests
class UserListRepository {
    func fetchUsers(quantity: Int) async throws -> [User] {
        return []
    }
}
