import Foundation

@MainActor
final class UserListViewModel: ObservableObject {
    @Published private(set) var users: [User] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let repository: UserListRepository
    private var currentPage: Int = 1
    private let pageSize: Int = 20

    init(repository: UserListRepository = UserListRepository()) {
        self.repository = repository
    }

    func fetchUsers() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        
        do {
            let newUsers = try await repository.fetchUsers(quantity: pageSize)
            self.users.append(contentsOf: newUsers)
            currentPage += 1
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }

    func reloadUsers() {
        Task {
            currentPage = 1
            users.removeAll()
            await fetchUsers()
        }
    }

    func shouldLoadMoreData(currentItem: User) -> Bool {
        // Logic to determine if more data should be loaded
        // For example, load more if we are near the end of the list
        guard !isLoading, let lastUser = users.last else { return false }
        return currentItem.id == lastUser.id
    }
}
