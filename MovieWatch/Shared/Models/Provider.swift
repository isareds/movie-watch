import Foundation
import SwiftData

@Model
final class Provider {
    enum Kind: String, Codable, CaseIterable, Identifiable {
        case flatrate
        case rent
        case buy
        
        var id: String { rawValue }
    }
    
    var id: UUID
    var name: String
    var logo: URL?
    var kind: Kind

    init(name: String,
         logo: URL? = nil,
         kind: Kind,
         id: UUID = .init()) {
        self.id = id
        self.name = name
        self.logo = logo
        self.kind = kind
    }
}
