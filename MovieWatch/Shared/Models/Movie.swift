//
//  Movie.swift
//  MovieWatch
//
//  Created by Isacco Rossi on 22/09/25.
//

import Foundation
import SwiftData

@Model
final class Movie {
    // Non serve un id “manuale” per SwiftData, ma lo manteniamo per compatibilità
    var id: UUID
    var title: String
    var year: Int?
    var plot: String?
    var posterURL: URL?
    var runtime: Int

    var providers: [Provider] = []

    var seen: Bool
    var watchPosition: Int
    var createdAt: Date
    var vote_average: Double?
    var vote_count: Int?
    
    var isFetching: Bool = false

    init(
        id: UUID = .init(),
        title: String,
        year: Int? = nil,
        plot: String? = nil,
        posterURL: URL? = nil,
        runtime: Int = 0,
        providers: [Provider] = [],
        seen: Bool = false,
        watchPosition: Int = 0,
        createdAt: Date = .now,
        isFetching: Bool = false,
        vote_average: Double? = nil,
        vote_count: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.year = year
        self.plot = plot
        self.posterURL = posterURL
        self.runtime = runtime
        self.providers = providers
        self.seen = seen
        self.watchPosition = watchPosition
        self.createdAt = createdAt
        self.isFetching = isFetching
        self.vote_average = vote_average
        self.vote_count = vote_count
    }

    var displayTitle: String {
        if let y = year { return "\(title) (\(y))" }
        return title
    }
}
