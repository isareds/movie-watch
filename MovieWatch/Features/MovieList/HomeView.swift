import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    
    @Query(sort: \Movie.createdAt, order: .reverse) private var movies: [Movie]
    @State private var searchStore = SearchStore()
    @FocusState private var searchFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                NoisyBackground()
                    .ignoresSafeArea()
                content
            }
            .navigationDestination(for: Movie.self) { movie in
                MovieDetailView(movie: movie)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                searchPanel
            }
        }
    }
    
    private var content: some View {
        List {
            moviesSection
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .listRowSeparator(.hidden)
        .contentMargins(.bottom, isSearchPanelVisible ? 240 : 120, for: .scrollContent)
    }
    
    private var isSearchPanelVisible: Bool {
        searchFieldFocused || shouldShowSearchResults
    }
    
    private var shouldShowSearchResults: Bool {
        let trimmed = trimmedSearchQuery
        return !trimmed.isEmpty || searchStore.isLoading || !searchStore.results.isEmpty
    }
    
    private var trimmedSearchQuery: String {
        searchStore.query.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var moviesSection: some View {
        Section {
            if movies.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "film")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Aggiungi un film dalla ricerca per iniziare.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .listRowBackground(Color.clear)
            } else {
                ForEach(Array(movies.enumerated()), id: \.element.id) { index, movie in
                    let isLast = index == movies.count - 1
                    NavigationLink(value: movie) {
                        MovieRowView(movie: movie, showSeparator: !isLast) {
                            movie.seen.toggle()
                            Haptics.light()
                        }
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                    .listRowBackground(Color.clear)
                }
            }
        }
    }
}

// MARK: - Helpers
private extension HomeView {
    var searchPanel: some View {
        VStack(spacing: 12) {
            if shouldShowSearchResults {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Risultati TMDB")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Spacer()
                        if !trimmedSearchQuery.isEmpty || !searchStore.results.isEmpty {
                            Button {
                                clearSearch(closeOverlay: true)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title3)
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Chiudi ricerca")
                        }
                    }
                    
                    searchResultsContent
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            searchField
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 0.8)
        }
        .shadow(radius: 12, y: 8)
        .padding(.horizontal)
        .padding(.bottom, 10)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: shouldShowSearchResults)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: searchFieldFocused)
    }
    
    var searchResultsContent: some View {
        Group {
            if searchStore.isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Ricerca in corso…")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if searchStore.results.isEmpty {
                Text(trimmedSearchQuery.isEmpty ? "Inizia a digitare per cercare su TMDB." : "Nessun risultato per \"\(trimmedSearchQuery)\".")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .minimumScaleFactor(0.85)
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(searchStore.results) { item in
                            Button {
                                addMovie(from: item)
                            } label: {
                                searchResultRow(for: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: 280)
            }
        }
    }
    
    var searchField: some View {
        HStack(spacing: 12) {
            TextField("Cerca su TMDB…", text: Binding(
                get: { searchStore.query },
                set: { searchStore.query = $0 }
            ))
            .focused($searchFieldFocused)
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
            .submitLabel(.search)
            .onSubmit {
                searchStore.searchImmediately()
            }
            
            if !trimmedSearchQuery.isEmpty {
                Button {
                    clearSearch(closeOverlay: false)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.callout)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.12))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 0.8)
        }
    }
    
    func clearSearch(closeOverlay: Bool) {
        searchStore.query = ""
        searchStore.results.removeAll()
        if closeOverlay {
            searchFieldFocused = false
        }
    }
    
    func addMovie(from item: TMDBSearchItem) {
        let title = item.title ?? "Senza titolo"
        let movie = Movie(title: title, isFetching: true)
        context.insert(movie)
        
        Task {
            do {
                let api = try MovieAPI()
                await api.enrich(movie: movie, in: context)
                await MainActor.run {
                    Haptics.success()
                    searchFieldFocused = false
                    searchStore.query = ""
                    searchStore.results.removeAll()
                }
            } catch {
                print("Errore aggiunta:", error.localizedDescription)
                await MainActor.run { movie.isFetching = false }
            }
        }
    }
    
    @ViewBuilder
    func searchResultRow(for item: TMDBSearchItem) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w154\(item.poster_path ?? "")")) { phase in
                switch phase {
                case .success(let image): image.resizable().scaledToFill()
                case .failure: searchPosterPlaceholder
                case .empty: ProgressView()
                @unknown default: searchPosterPlaceholder
                }
            }
            .frame(width: 50, height: 75)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .shadow(radius: 8, y: 6)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title ?? "Senza titolo")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                if let date = item.release_date, !date.isEmpty {
                    Text(String(date.prefix(4)))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "plus.circle.fill")
                .font(.title3)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.mint)
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.08))
        }
    }
    
    var searchPosterPlaceholder: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Color.white.opacity(0.1))
            .overlay(
                Image(systemName: "film")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.35))
            )
    }
}
