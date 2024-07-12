import Foundation

struct User: Identifiable {
    var id = UUID()
    let name: Name
    let dob: Dob
    let picture: Picture

    init(user: UserListResponse.User) {
        self.name = .init(title: user.name.title, first: user.name.first, last: user.name.last)
        self.dob = .init(date: user.dob.date, age: user.dob.age)
        self.picture = .init(large: user.picture.large, medium: user.picture.medium, thumbnail: user.picture.thumbnail)
    }

    struct Dob: Codable {
        let date: String
        let age: Int
    }

    struct Name: Codable {
        let title, first, last: String
    }

    struct Picture: Codable {
        let large, medium, thumbnail: String
    }
}
