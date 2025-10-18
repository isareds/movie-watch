import Foundation
import SwiftData

enum MovieAPIError: Error, LocalizedError {
    case missingToken, notFound, badStatus(Int), invalidResponse
    var errorDescription: String? {
        switch self {
        case .missingToken: return "Token TMDB mancante"
        case .notFound: return "Nessun risultato TMDB"
        case .badStatus(let c): return "HTTP \(c)"
        case .invalidResponse: return "Risposta non valida"
        }
    }
}

final class MovieAPI {
    private let token: String
    private let language: String
    private let watchRegion: String

    init() throws {
        let configuration = try MovieAPI.loadConfiguration()
        self.token = configuration.token
        self.language = configuration.language
        self.watchRegion = configuration.watchRegion
    }

    private static func loadConfiguration() throws -> (token: String, language: String, watchRegion: String) {
        if let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
           let data = try? Data(contentsOf: url),
           let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] {
            let token = (plist["TMDB_READ_TOKEN"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let language = (plist["LANGUAGE"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let watchRegion = (plist["WATCH_REGION"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            if !token.isEmpty {
                return (
                    token: token,
                    language: (language?.isEmpty == false ? language : nil) ?? "it-IT",
                    watchRegion: (watchRegion?.isEmpty == false ? watchRegion : nil) ?? "IT"
                )
            }
        }

        if let token = Bundle.main.object(forInfoDictionaryKey: "TMDB_READ_TOKEN") as? String {
            let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                let language = (Bundle.main.object(forInfoDictionaryKey: "LANGUAGE") as? String)?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let watchRegion = (Bundle.main.object(forInfoDictionaryKey: "WATCH_REGION") as? String)?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                return (
                    token: trimmed,
                    language: (language?.isEmpty == false ? language : nil) ?? "it-IT",
                    watchRegion: (watchRegion?.isEmpty == false ? watchRegion : nil) ?? "IT"
                )
            }
        }

        throw MovieAPIError.missingToken
    }

    private func request(_ url: URL) throws -> URLRequest {
        var r = URLRequest(url: url)
        r.timeoutInterval = 12
        r.setValue("application/json", forHTTPHeaderField: "accept")
        r.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return r
    }

    /// Comodo helper per immagini: w500 è una size ottima per poster.
    private func buildImageURL(_ path: String?, size: String = "w500") -> URL? {
        guard let p = path else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/\(size)\(p)")
    }

    /// Costruisce l'URL per i loghi, usando dimensioni ridotte adatte all'interfaccia.
    private func buildLogoURL(_ path: String?, size: String = "w92") -> URL? {
        guard let p = path else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/\(size)\(p)")
    }

    /// Flusso: search → details → watch/providers (IT) → aggiorna Movie
    func enrich(movie: Movie, in context: ModelContext) async {
        await MainActor.run { movie.isFetching = true }
        defer { Task { await MainActor.run { movie.isFetching = false } } }

        do {
            // 1) SEARCH
            let q = movie.title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? movie.title
            let searchURL = URL(string:
              "https://api.themoviedb.org/3/search/movie?query=\(q)&include_adult=false&language=\(language)&page=1"
            )!

            let (sdata, sresp) = try await URLSession.shared.data(for: try request(searchURL))
            guard let shttp = sresp as? HTTPURLResponse, (200..<300).contains(shttp.statusCode) else {
                throw MovieAPIError.badStatus((sresp as? HTTPURLResponse)?.statusCode ?? -1)
            }
            

            let search = try JSONDecoder().decode(TMDBSearchResponse.self, from: sdata)
            guard let first = search.results.first else { throw MovieAPIError.notFound }

            // 2) DETAILS
            let detailsURL = URL(string:
              "https://api.themoviedb.org/3/movie/\(first.id)?language=\(language)"
            )!
            let (ddata, dresp) = try await URLSession.shared.data(for: try request(detailsURL))
            guard let dhttp = dresp as? HTTPURLResponse, (200..<300).contains(dhttp.statusCode) else {
                throw MovieAPIError.badStatus((dresp as? HTTPURLResponse)?.statusCode ?? -1)
            }
            let details = try JSONDecoder().decode(TMDBMovieDetails.self, from: ddata)

            // 3) WATCH PROVIDERS (IT)
            let providersURL = URL(string:
              "https://api.themoviedb.org/3/movie/\(first.id)/watch/providers"
            )!
            let (wdata, wresp) = try await URLSession.shared.data(for: try request(providersURL))
            guard let whttp = wresp as? HTTPURLResponse, (200..<300).contains(whttp.statusCode) else {
                throw MovieAPIError.badStatus((wresp as? HTTPURLResponse)?.statusCode ?? -1)
            }
            let providers = try JSONDecoder().decode(TMDBWatchProvidersResponse.self, from: wdata)
            let it = providers.results[watchRegion]

            // 4) Aggiorna il tuo modello
            let providerModels = await MainActor.run { makeProviders(from: it) }
            await MainActor.run {
                
                if movie.year == nil {
                    if let yStr = details.release_date?.prefix(4),
                       let y = Int(yStr) {
                        movie.year = y
                    }
                }
                
                movie.plot = movie.plot ?? details.overview
                
                if movie.posterURL == nil {
                    movie.posterURL = buildImageURL(details.poster_path)
                }

                if let runtime = details.runtime {
                    movie.runtime = runtime
                    if movie.watchPosition > runtime {
                        movie.watchPosition = runtime
                    }
                }
                
                movie.vote_average = details.vote_average
                movie.vote_count = details.vote_count
                
                movie.providers.forEach { context.delete($0) }
                movie.providers.removeAll()
                movie.providers.append(contentsOf: providerModels)
            }
            
        } catch {
            print("TMDB enrich error:", error.localizedDescription)
        }
    }
    
    func searchTitles(_ query: String) async throws -> [TMDBSearchItem] {
        let q = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let url = URL(string:
          "https://api.themoviedb.org/3/search/movie?query=\(q)&include_adult=false&language=it-IT&page=1"
        )!
        let (data, resp) = try await URLSession.shared.data(for: try request(url))
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw MovieAPIError.badStatus((resp as? HTTPURLResponse)?.statusCode ?? -1)
        }
        let decoded = try JSONDecoder().decode(TMDBSearchResponse.self, from: data)
        return decoded.results
    }

    private func makeProviders(from region: TMDBRegionProviders?) -> [Provider] {
        guard let region else { return [] }
        
        let flatrate = (region.flatrate ?? []).map {
            Provider(
                name: $0.provider_name,
                logo: buildLogoURL($0.logo_path),
                kind: .flatrate
            )
        }
        let rent = (region.rent ?? []).map {
            Provider(
                name: $0.provider_name,
                logo: buildLogoURL($0.logo_path),
                kind: .rent
            )
        }
        let buy = (region.buy ?? []).map {
            Provider(
                name: $0.provider_name,
                logo: buildLogoURL($0.logo_path),
                kind: .buy
            )
        }
        
        let combined = flatrate + rent + buy
        // Deduplica eventuali provider ripetuti
        var unique: [String: Provider] = [:]
        for provider in combined {
            unique["\(provider.name)-\(provider.kind.rawValue)"] = provider
        }
        let order: [Provider.Kind: Int] = [.flatrate: 0, .rent: 1, .buy: 2]
        return unique.values.sorted { lhs, rhs in
            let lhsOrder = order[lhs.kind, default: 3]
            let rhsOrder = order[rhs.kind, default: 3]
            if lhsOrder != rhsOrder {
                return lhsOrder < rhsOrder
            }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }
}

