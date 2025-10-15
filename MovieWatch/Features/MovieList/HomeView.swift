import SwiftUI
import Observation
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    
    @Query(sort: \Movie.createdAt, order: .reverse) private var movies: [Movie]
    @State private var newTitle = ""
    @FocusState private var searchFieldFocused: Bool
    
    @State private var isShowingSearch = false
    @State private var isSearchBarVisible = true
    @State private var lastScrollOffset: CGFloat = 0
    @State private var hasCapturedScrollOffset = false
    @State private var searchStore = SearchStore()

    var body: some View {
        NavigationStack {
            ZStack {
                NoisyBackground()

                VStack(spacing: 16) {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(Array(movies.enumerated()), id: \.element.id) { index, movie in
                                let isLast = index == movies.count - 1
                                NavigationLink(value: movie) {
                                    MovieRowView(movie: movie, showSeparator: !isLast) {
                                        movie.seen.toggle()
                                        Haptics.light()
                                    }
                                }
                                .buttonStyle(.plain)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: movies.count)
                            }
                            Spacer(minLength: 80)
                        }
                        .padding(.horizontal)
                        .background(
                            GeometryReader { proxy in
                                Color.clear
                                    .preference(key: ScrollOffsetPreferenceKey.self, value: proxy.frame(in: .named("homeScroll")).minY)
                            }
                        )
                    }
                    .coordinateSpace(name: "homeScroll")
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self, perform: handleScrollChange)
                }

                inputBar
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                    .offset(y: isSearchBarVisible ? 0 : 140)
                    .opacity(isSearchBarVisible ? 1 : 0)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .navigationDestination(for: Movie.self) { movie in
                MovieDetailView(movie: movie)
            }
            .navigationTitle("MovieGlass")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var inputBar: some View {
        let queryBinding = Binding(
            get: { searchStore.query },
            set: { searchStore.query = $0 }
        )
        
        return VStack(spacing: 12) {
            if isShowingSearch {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Risultati TMDB")
                            .font(.headline)
                        Spacer()
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
                    
                    searchOverlayContent
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.8)
                }
                .shadow(radius: 12, y: 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            searchTextField(queryBinding: queryBinding)
        }
        .onChange(of: searchFieldFocused) { _, isFocused in
            if isFocused {
                showSearchBar()
            }
            updateSearchOverlayVisibility()
        }
        .onChange(of: searchStore.query) { _, _ in
            updateSearchOverlayVisibility()
        }
        .onChange(of: searchStore.isLoading) { _, _ in
            updateSearchOverlayVisibility()
        }
        .onChange(of: searchStore.results.count) { _, _ in
            updateSearchOverlayVisibility()
        }
    }

    private func searchTextField(queryBinding: Binding<String>) -> some View {
        ZStack(alignment: .trailing) {
            TextField("Cerca su TMDB…", text: queryBinding)
                .focused($searchFieldFocused)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .submitLabel(.search)
                .onTapGesture {
                    showSearchBar()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        isShowingSearch = true
                    }
                }
                .onSubmit {
                    searchStore.searchImmediately()
                }
                .frame(maxWidth: .infinity)
            
            if !searchStore.query.isEmpty {
                Button {
                    clearSearch(closeOverlay: false)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.footnote)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                        .padding(.trailing, 12)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Cancella ricerca")
            }
        }
    }

    @ViewBuilder
    private var searchOverlayContent: some View {
        let trimmed = trimmedSearchQuery
        if searchStore.isLoading {
            HStack(spacing: 8) {
                ProgressView()
                Text("Ricerca in corso…")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else if searchStore.results.isEmpty {
            Text(trimmed.isEmpty ? "Inizia a digitare per cercare su TMDB." : "Nessun risultato per \"\(trimmed)\".")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .minimumScaleFactor(0.8)
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(searchStore.results) { item in
                        Button {
                            selectSearchResult(item)
                        } label: {
                            searchResultRow(for: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(maxHeight: 320)
        }
    }

    @ViewBuilder
    private func searchResultRow(for item: TMDBSearchItem) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w154\(item.poster_path ?? "")")) { phase in
                switch phase {
                case .success(let image): image.resizable().scaledToFill()
                case .failure: searchPosterPlaceholder
                case .empty: ProgressView()
                @unknown default: searchPosterPlaceholder
                }
            }
            .frame(width: 60, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title ?? "Senza titolo")
                    .font(.headline)
                if let date = item.release_date, !date.isEmpty {
                    Text(String(date.prefix(4)))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "plus.circle.fill")
                .font(.title3)
                .foregroundStyle(.mint)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.08))
        }
    }

    private var searchPosterPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(.ultraThinMaterial)
            .overlay(Image(systemName: "film").opacity(0.3))
    }

    private var trimmedSearchQuery: String {
        searchStore.query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func selectSearchResult(_ item: TMDBSearchItem) {
        let title = item.title ?? "Senza titolo"
        let movie = Movie(title: title, isFetching: true)
        context.insert(movie)
        
        Task {
            do {
                let api = try MovieAPI()
                await api.enrich(movie: movie, in: context)
                await MainActor.run {
                    Haptics.success()
                    searchStore.query = ""
                    searchStore.results.removeAll()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        isShowingSearch = false
                    }
                    searchFieldFocused = false
                }
            } catch {
                print("Errore aggiunta:", error.localizedDescription)
            }
        }
    }

    private func addMovie() {
        let clean = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        
        let m = Movie(title: clean, isFetching: true)
        context.insert(m)
        newTitle = ""
        Haptics.success()
        
        Task {
            do {
                let api = try MovieAPI()
                await api.enrich(movie: m, in: context)
            } catch {
                print("MovieAPI error: ", error.localizedDescription)
                await MainActor.run { m.isFetching = false }
            }
        }
    }
}

// MARK: - Scroll handling & helpers
private extension HomeView {
    func handleScrollChange(_ value: CGFloat) {
        if !hasCapturedScrollOffset {
            hasCapturedScrollOffset = true
            lastScrollOffset = value
            return
        }
        
        let delta = value - lastScrollOffset
        if abs(delta) > 12 {
            if delta < 0 && value < -20 {
                hideSearchBarIfNeeded()
            } else if delta > 0 {
                showSearchBar()
            }
        }
        
        if value >= -10 {
            showSearchBar()
        }
        
        lastScrollOffset = value
    }
    
    func hideSearchBarIfNeeded() {
        guard isSearchBarVisible, !searchFieldFocused, !isShowingSearch else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            isSearchBarVisible = false
        }
    }
    
    func showSearchBar() {
        guard !isSearchBarVisible else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            isSearchBarVisible = true
        }
    }
    
    func updateSearchOverlayVisibility() {
        let shouldShow = searchFieldFocused
            || !trimmedSearchQuery.isEmpty
            || searchStore.isLoading
            || !searchStore.results.isEmpty
        
        guard shouldShow != isShowingSearch else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            isShowingSearch = shouldShow
        }
    }
    
    func clearSearch(closeOverlay: Bool) {
        searchStore.query = ""
        searchStore.results.removeAll()
        if closeOverlay {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                isShowingSearch = false
            }
            searchFieldFocused = false
        }
    }
}

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
