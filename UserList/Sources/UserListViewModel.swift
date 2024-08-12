import Foundation

@MainActor
final class UserListViewModel: ObservableObject {
    @Published private(set) var users: [User] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let repository: UserListRepository

    init(repository: UserListRepository = UserListRepository()) {
        self.repository = repository
    }

    func fetchUsers() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let newUsers = try await repository.fetchUsers(quantity: 20)
            self.users = newUsers
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }

    func reloadUsers() {
        Task {
            await fetchUsers()
        }
    }
}
