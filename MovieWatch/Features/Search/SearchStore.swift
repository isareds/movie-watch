import Foundation
import SwiftData

@MainActor
@Observable
final class SearchStore {
    var query = "" {
        didSet {
            scheduleSearch()
        }
    }
    var results: [TMDBSearchItem] = []
    var isLoading = false

    private var task: Task<Void, Never>? = nil

    func searchImmediately() {
        task?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            results.removeAll()
            isLoading = false
            task = nil
            return
        }

        task = Task {
            await performSearch(for: trimmed)
        }
    }

    private func scheduleSearch() {
        task?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            results.removeAll()
            isLoading = false
            task = nil
            return
        }

        task = Task { [trimmed] in
            try? await Task.sleep(for: .milliseconds(320))
            guard !Task.isCancelled else { return }
            await performSearch(for: trimmed)
        }
    }

    private func performSearch(for currentQuery: String) async {
        do {
            let api = try MovieAPI()
            isLoading = true
            defer {
                isLoading = false
                task = nil
            }

            let found = try await api.searchTitles(currentQuery)
            if currentQuery == query.trimmingCharacters(in: .whitespacesAndNewlines) {
                results = found
            }
        } catch {
            print("Search error:", error.localizedDescription)
        }
    }
}
