import XCTest
@testable import UserList

@MainActor
final class UserListViewModelTests: XCTestCase {
    var viewModel: UserListViewModel!
    var mockRepository: UserListRepository!

    // Mock successful data request
    let mockExecuteDataRequest: (URLRequest) async throws -> (Data, URLResponse) = { request in
        let mockUser1 = UserListResponse.User(
            name: .init(title: "Mr", first: "John", last: "Doe"),
            dob: .init(date: "1990-01-01", age: 31),
            picture: .init(large: "https://example.com/large.jpg", medium: "https://example.com/medium.jpg", thumbnail: "")
        )
        let mockUser2 = UserListResponse.User(
            name: .init(title: "Ms", first: "Jane", last: "Smith"),
            dob: .init(date: "1995-02-15", age: 26),
            picture: .init(large: "", medium: "https://example.com/medium.jpg", thumbnail: "")
        )
        let mockResponse = UserListResponse(results: [mockUser1, mockUser2])
        let data = try JSONEncoder().encode(mockResponse)
        let urlResponse = URLResponse(url: request.url!, mimeType: nil, expectedContentLength: data.count, textEncodingName: nil)
        return (data, urlResponse)
    }

    // Mock failed data request
    let mockExecuteDataRequestFailure: (URLRequest) async throws -> (Data, URLResponse) = { request in
        throw URLError(.badServerResponse)
    }

    func testFetchUsersSuccess() async throws {
        // Given
        mockRepository = UserListRepository(executeDataRequest: mockExecuteDataRequest)
        viewModel = UserListViewModel(repository: mockRepository)
        
        // When
        let expectation = self.expectation(description: "Fetch users successfully")
        Task {
            await viewModel.fetchUsers()
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 2)
        
        // Ensure view model is updated on the main thread
        await MainActor.run {
            // Then
            XCTAssertFalse(viewModel.isLoading, "Expected isLoading to be false after fetch")
            XCTAssertEqual(viewModel.users.count, 2, "Expected users count to be 2 after fetch")
            
            XCTAssertEqual(viewModel.users[0].name.first, "John")
            XCTAssertEqual(viewModel.users[0].name.last, "Doe")
            XCTAssertEqual(viewModel.users[0].dob.age, 31)
            XCTAssertEqual(viewModel.users[0].picture.large, "https://example.com/large.jpg")
            
            XCTAssertEqual(viewModel.users[1].name.first, "Jane")
            XCTAssertEqual(viewModel.users[1].name.last, "Smith")
            XCTAssertEqual(viewModel.users[1].dob.age, 26)
            XCTAssertEqual(viewModel.users[1].picture.medium, "https://example.com/medium.jpg")
        }
    }

    func testFetchUsersFailure() async throws {
        // Given
        mockRepository = UserListRepository(executeDataRequest: mockExecuteDataRequestFailure)
        viewModel = UserListViewModel(repository: mockRepository)

        // When
        let expectation = self.expectation(description: "Fetch users failed")
        Task {
            await viewModel.fetchUsers()
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 2)

        // Ensure view model is updated on the main thread
        await MainActor.run {
            // Then
            XCTAssertTrue(viewModel.users.isEmpty, "Expected users to be empty after failed fetch")
            XCTAssertNotNil(viewModel.errorMessage, "Expected errorMessage to be set after failed fetch")
        }
    }
    
    func testFetchUsersFailureState() async throws {
        // Given
        mockRepository = UserListRepository(executeDataRequest: mockExecuteDataRequestFailure)
        viewModel = UserListViewModel(repository: mockRepository)
        
        // When
        let expectation = self.expectation(description: "Fetch users failed")
        Task {
            await viewModel.fetchUsers()
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 2)
        
        // Ensure view model is updated on the main thread
        await MainActor.run {
            // Then
            XCTAssertTrue(viewModel.users.isEmpty, "Expected users to be empty after failed fetch")
            XCTAssertNotNil(viewModel.errorMessage, "Expected errorMessage to be set after failed fetch")
        }
    }
    
    
    func testFetchUsersFailure() {
    // Given
      mockRepository = UserListRepository(executeDataRequest: mockExecuteDataRequestFailure)
      viewModel = UserListViewModel(repository: mockRepository)
      let expectation = self.expectation(description: "Fetch users failed")
      // When
      Task {
          await viewModel.fetchUsers()
          expectation.fulfill()
      }
      waitForExpectations(timeout: 2, handler: nil)
      // Then
      XCTAssertEqual(viewModel.users.count, 0)
  }
    
    func testFetchUsersEmptyResponse() async throws {
        // Given
        let mockEmptyResponse: (URLRequest) async throws -> (Data, URLResponse) = { request in
            let mockResponse = UserListResponse(results: [])
            let data = try JSONEncoder().encode(mockResponse)
            let urlResponse = URLResponse(url: request.url!, mimeType: nil, expectedContentLength: data.count, textEncodingName: nil)
            return (data, urlResponse)
        }
        mockRepository = UserListRepository(executeDataRequest: mockEmptyResponse)
        viewModel = UserListViewModel(repository: mockRepository)
        
        // When
        let expectation = self.expectation(description: "Fetch users with empty response")
        Task {
            await viewModel.fetchUsers()
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 2)

        // Then
        XCTAssertTrue(viewModel.users.isEmpty, "Expected users to be empty after fetch with empty response")
        XCTAssertNil(viewModel.errorMessage, "Error message should be nil after fetch with empty response")
    }
    
    func testFetchUsersFailureEdgeCase() async throws {
        // Given
        mockRepository = UserListRepository(executeDataRequest: mockExecuteDataRequestFailure)
        viewModel = UserListViewModel(repository: mockRepository)
        
        // When
        let expectation = self.expectation(description: "Fetch users failed with error")
        Task {
            await viewModel.fetchUsers()
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 2)

        // Then
        XCTAssertTrue(viewModel.users.isEmpty, "Expected users to be empty after failed fetch")
        XCTAssertNotNil(viewModel.errorMessage, "Expected error message to be set after failed fetch")
    }

    
    func testReloadUsersAfterFailure() async throws {
        // Given
        mockRepository = UserListRepository(executeDataRequest: mockExecuteDataRequestFailure)
        viewModel = UserListViewModel(repository: mockRepository)
        await viewModel.fetchUsers() // simulate failure

        // When
        mockRepository = UserListRepository(executeDataRequest: mockExecuteDataRequest)
        viewModel = UserListViewModel(repository: mockRepository)
        
        let expectation = self.expectation(description: "Reload users after failure")
        Task {
            await viewModel.reloadUsers()
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 2)

        // Then
        XCTAssertFalse(viewModel.isLoading, "Expected isLoading to be false after reload")
        XCTAssertEqual(viewModel.users.count, 2, "Expected users count to be 2 after successful reload")
        XCTAssertNil(viewModel.errorMessage, "Error message should be nil after successful reload")
    }


}
