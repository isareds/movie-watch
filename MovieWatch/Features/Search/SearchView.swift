import SwiftUI
import SwiftData

struct SearchView: View {
    @Bindable var store: SearchStore
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                // Campo di ricerca
                TextField("Cerca un film…", text: $store.query)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                    .submitLabel(.search)
                    .onSubmit {
                        store.searchImmediately()
                    }

                if store.isLoading {
                    ProgressView("Ricerca in corso…")
                        .padding(.top, 20)
                } else if store.results.isEmpty {
                    Spacer()
                    ContentUnavailableView("Nessun risultato", systemImage: "film.stack")
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(store.results) { item in
                                Button {
                                    addMovie(from: item)
                                } label: {
                                    HStack(spacing: 12) {
                                        AsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w154\(item.poster_path ?? "")")) { phase in
                                            switch phase {
                                            case .success(let image): image.resizable().scaledToFill()
                                            case .failure: placeholder
                                            case .empty: ProgressView()
                                            @unknown default: placeholder
                                            }
                                        }
                                        .frame(width: 60, height: 90)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))

                                        VStack(alignment: .leading) {
                                            Text(item.title ?? "Senza titolo")
                                                .font(.headline)
                                            if let date = item.release_date, !date.isEmpty {
                                                Text(String(date.prefix(4)))
                                                    .font(.subheadline).opacity(0.7)
                                            }
                                        }
                                        Spacer()
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(.mint)
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 6)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Cerca su TMDB")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Chiudi") { dismiss() }
                }
            }
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(.ultraThinMaterial)
            .overlay(Image(systemName: "film").opacity(0.3))
    }

    private func addMovie(from item: TMDBSearchItem) {
        // Crea film e arricchisci come nello step 6
        let title = item.title ?? "Senza titolo"
        let m = Movie(title: title, isFetching: true)
        context.insert(m)

        Task {
            do {
                let api = try MovieAPI()
                await api.enrich(movie: m, in: context)
                await MainActor.run { dismiss() }
            } catch {
                print("Errore aggiunta:", error.localizedDescription)
            }
        }
    }
}
