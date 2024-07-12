import Foundation

struct UserListResponse: Codable {
    let results: [User]

    struct User: Codable {
        let name: Name
        let dob: Dob
        let picture: Picture

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
}
