import SwiftUI

struct MovieRowView: View {
    let movie: Movie
    var showSeparator: Bool
    let onToggleSeen: () -> Void
    
    init(
        movie: Movie,
        showSeparator: Bool = true,
        onToggleSeen: @escaping () -> Void
    ) {
        self.movie = movie
        self.showSeparator = showSeparator
        self.onToggleSeen = onToggleSeen
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Button(action: onToggleSeen) {
                    Image(systemName: movie.seen ? "checkmark.circle.fill" : "checkmark.circle")
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(movie.seen ? Color.green.opacity(0.85) : Color.white.opacity(0.55))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(movie.seen ? "Segna come non visto" : "Segna come visto")
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(movie.displayTitle)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .strikethrough(movie.seen, color: .white.opacity(0.45))
                            .opacity(movie.seen ? 0.65 : 1)
                        
                        Spacer()
                        
                        if let rating = ratingText {
                            ratingView(with: rating)
                        }
                    }
                    
                    if movie.isFetching {
                        Text("Aggiornamento in corso…")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.55))
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.35))
            }
            
            if !providerCategories.isEmpty {
                HStack(spacing: 8) {
                    ForEach(providerCategories) { category in
                        providerCategoryBadge(for: category)
                    }
                }
                .padding(.leading, 44)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .overlay(alignment: .bottom) {
            if showSeparator {
                separator
            }
        }
    }
    
    private var separator: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(height: 0.6)
            .padding(.leading, 44)
    }
    
    private var ratingText: String? {
        guard let value = movie.vote_average else { return nil }
        return value.formatted(.number.precision(.fractionLength(1)))
    }
    
    @ViewBuilder
    private func ratingView(with rating: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.caption)
                .foregroundStyle(.yellow)
            Text(rating)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background {
            Capsule()
                .fill(Color.white.opacity(0.08))
        }
        .overlay {
            Capsule()
                .stroke(Color.white.opacity(0.18), lineWidth: 0.6)
        }
    }
    
    private var providerCategories: [ProviderCategory] {
        Provider.Kind.allCases.compactMap { kind in
            let filtered = movie.providers.filter { $0.kind == kind }
            guard !filtered.isEmpty else { return nil }
            return ProviderCategory(kind: kind, providers: filtered)
        }
    }
    
    @ViewBuilder
    private func providerCategoryBadge(for category: ProviderCategory) -> some View {
        HStack(spacing: 6) {
            providerLogoStack(for: category.providers)
            Text(category.displayLabel)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(category.tint)
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 10)
        .background {
            Capsule()
                .fill(category.tint.opacity(0.18))
        }
        .overlay {
            Capsule()
                .stroke(category.tint.opacity(0.35), lineWidth: 0.6)
        }
    }
    
    private func providerLogoStack(for providers: [Provider]) -> some View {
        let logos = Array(providers.prefix(3))
        return HStack(spacing: 6) {
            HStack(spacing: -8) {
                ForEach(logos, id: \.id) { provider in
                    providerLogo(for: provider.logo)
                        .frame(width: 22, height: 22)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.black.opacity(0.25), lineWidth: 0.6))
                        .shadow(radius: 2, y: 1)
                }
            }
            
            if providers.count > 3 {
                Text("+\(providers.count - 3)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }
    
    private func providerLogo(for url: URL?) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure, .empty:
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        Image(systemName: "play.fill")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.7))
                    )
            @unknown default:
                Circle()
                    .fill(Color.white.opacity(0.1))
            }
        }
    }
    
    private struct ProviderCategory: Identifiable {
        let kind: Provider.Kind
        let providers: [Provider]
        
        var id: Provider.Kind { kind }
        
        var tint: Color {
            switch kind {
            case .flatrate: return .green
            case .rent: return .orange
            case .buy: return .blue
            }
        }
        
        var displayLabel: String {
            switch kind {
            case .flatrate: return "Incluso"
            case .rent: return "Noleggio"
            case .buy: return "Acquisto"
            }
        }
    }
}
