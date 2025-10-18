import Foundation
import SwiftData

@Model
final class Credit {
    var id: UUID
    var known_for_department: String
    var name: String
    var character: String?
    var profile_path: URL?
    var job: String?

    init(
        id: UUID = .init(),
        known_for_department: String,
        name: String,
        character: String? = nil,
        profile_path: URL? = nil,
        job: String? = nil
    ) {
        self.id = id
        self.known_for_department = known_for_department
        self.name = name
        self.character = character
        self.profile_path = profile_path
        self.job = job
    }
}


@Model
final class Credits {
    var id: UUID
    var cast: [Credit]
    var crew: [Credit]

    init(id: UUID = .init(), cast: [Credit] = [], crew: [Credit] = []) {
        self.id = id
        self.cast = cast
        self.crew = crew
    }
}
