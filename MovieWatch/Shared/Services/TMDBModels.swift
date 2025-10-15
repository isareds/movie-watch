import Foundation

struct TMDBSearchResponse: Decodable {
    let results: [TMDBSearchItem]
}

struct TMDBSearchItem: Decodable, Identifiable {
    let id: Int
    let title: String?
    let release_date: String?
    let poster_path: String?
}

struct TMDBMovieDetails: Decodable {
    let id: Int
    let title: String
    let overview: String?
    let poster_path: String?
    let release_date: String?
    let vote_average: Double?
    let vote_count: Int?
}

struct TMDBWatchProvidersResponse: Decodable {
    let results: [String: TMDBRegionProviders]
}

struct TMDBRegionProviders: Decodable {
    let flatrate: [TMDBProvider]?
    let rent: [TMDBProvider]?
    let buy: [TMDBProvider]?
}

struct TMDBProvider: Decodable {
    let provider_id: Int
    let provider_name: String
    let logo_path: String?
}
