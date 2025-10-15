//
//  MovieStore.swift
//  MovieWatch
//
//  Created by Isacco Rossi on 22/09/25.
//
import Foundation
import Observation

@Observable
final class MovieStore {
    var movies: [Movie] = [
            .init(title: "Interstellar", year: 2014, plot: nil),
            .init(title: "Lo Hobbit", year: 2012),
            .init(title: "Io sono leggenda", year: 2007)
        ]
    
    func add(title: String) {
        let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        movies.insert(.init(title: clean), at: 0)
    }
    
    func toggleSeen(id: UUID) {
        guard let index = movies.firstIndex(where: { $0.id == id}) else { return }
        movies[index].seen.toggle()
    }
    
    func remove(id: UUID) {
        movies.removeAll { $0.id == id }
    }

    func update(id: UUID, mutate: (inout Movie) -> Void) {
        guard let i = movies.firstIndex(where: { $0.id == id }) else { return }
        mutate(&movies[i])
    }
}
