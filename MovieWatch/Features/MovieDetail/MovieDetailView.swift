import SwiftUI
import Observation
import SwiftData

struct MovieDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @Bindable var movie: Movie

    var body: some View {
        GeometryReader { proxy in
            let coverHeight = max(proxy.size.height * 0.5, 280)
            let contentTopInset = coverHeight * 0.6
            
            ZStack(alignment: .top) {
                heroBackground(height: coverHeight)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        headerSection
                        plotSection
                        availabilitySection
                    }
                    .padding(.horizontal)
                    .padding(.top, contentTopInset)
                    .padding(.bottom, 60)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        deleteMovie()
                    } label: {
                        Label {
                            Text("Elimina")
                                .foregroundStyle(Color.red.opacity(0.9))
                        } icon: {
                            Image(systemName: "trash")
                                .foregroundStyle(Color.red.opacity(0.9))
                        }
                    }
                    
                    Button {
                        refreshMovie()
                    } label: {
                        Label {
                            Text("Aggiorna")
                                .foregroundStyle(.white.opacity(0.9))
                        } icon: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundStyle(.white.opacity(0.9))
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.9))
                }
                
                Button {
                    toggleSeen()
                } label: {
                    Image(systemName: movie.seen ? "checkmark.circle.fill" : "checkmark.circle")
                        .font(.title3)
                        .foregroundStyle(movie.seen ? Color.green.opacity(0.85) : Color.green.opacity(0.6))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(movie.seen ? "Segna come non visto" : "Segna come visto")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Sections
private extension MovieDetailView {
    var headerSection: some View {
        detailSection {
            HStack(alignment: .top, spacing: 20) {
                PosterView(url: movie.posterURL)
                    .frame(width: 140, height: 210)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(radius: 14, y: 10)
                
                VStack(alignment: .leading, spacing: 14) {
                    Text(movie.displayTitle)
                        .font(.title2.bold())
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(primaryTextColor)
                    
                    ratingSummary
                    
                    if let year = movie.year {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.subheadline)
                                .foregroundStyle(secondaryTextColor)
                            Text("\(year)")
                                .font(.subheadline)
                                .foregroundStyle(secondaryTextColor)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }
    
    var plotSection: some View {
        detailSection(alignment: .leading, spacing: 12) {
            Text("Trama")
                .font(.headline)
                .foregroundStyle(primaryTextColor)
            if let plot = movie.plot, !plot.isEmpty {
                Text(plot)
                    .lineSpacing(4)
                    .foregroundStyle(primaryTextColor)
            } else {
                Text("Nessuna trama disponibile. La aggiungeremo con lo scraper/API.")
                    .font(.callout)
                    .foregroundStyle(secondaryTextColor)
            }
        }
    }
    
    @ViewBuilder
    var availabilitySection: some View {
        let groups = providerGroups
        if groups.isEmpty {
            detailSection(alignment: .leading, spacing: 12) {
                Text("Disponibile su")
                    .font(.headline)
                    .foregroundStyle(primaryTextColor)
                Text("Nessuna piattaforma segnalata al momento.")
                    .font(.subheadline)
                    .foregroundStyle(secondaryTextColor)
            }
        } else {
            ForEach(groups, id: \.title) { group in
                detailSection(alignment: .leading, spacing: 16) {
                    Text(group.title)
                        .font(.headline)
                        .foregroundStyle(primaryTextColor)
                    LazyVStack(spacing: 12) {
                        ForEach(Array(group.providers.enumerated()), id: \.element.id) { index, provider in
                            providerRow(for: provider)
                            if index < group.providers.count - 1 {
                                Divider()
                                    .overlay(sectionStrokeColor.opacity(0.6))
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Subviews & Helpers
private extension MovieDetailView {
    @ViewBuilder
    var ratingSummary: some View {
        if let ratingText = ratingDisplayText {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.title3)
                    Text(ratingText)
                        .font(.title3.bold())
                        .foregroundStyle(primaryTextColor)
                }
                Text(reviewCountText)
                    .font(.subheadline)
                    .foregroundStyle(secondaryTextColor)
            }
        } else {
            Text(reviewCountText)
                .font(.subheadline)
                .foregroundStyle(secondaryTextColor)
        }
    }
    
    func detailSection<Content: View>(
        alignment: HorizontalAlignment = .leading,
        spacing: CGFloat = 16,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        VStack(alignment: alignment, spacing: spacing, content: content)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(22)
            .foregroundStyle(primaryTextColor)
            .background {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(sectionBackgroundColor)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(sectionStrokeColor, lineWidth: 0.6)
            }
    }
    
    func heroBackground(height: CGFloat) -> some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                BackdropView(url: movie.posterURL)
                    .frame(height: height)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .overlay {
                        LinearGradient(
                            colors: [
                                .black.opacity(0.0),
                                .black.opacity(0.45),
                                .black
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                Spacer()
            }
        }
    }
    
    func toggleSeen() {
        movie.seen.toggle()
        Haptics.light()
        if movie.seen {
            Haptics.success()
        }
    }
    
    func deleteMovie() {
        context.delete(movie)
        try? context.save()
        dismiss()
        Haptics.success()
    }
    
    func refreshMovie() {
        Task {
            do {
                let api = try MovieAPI()
                await api.enrich(movie: movie, in: context)
                await MainActor.run {
                    Haptics.light()
                }
            } catch {
                print("Refresh error:", error.localizedDescription)
                await MainActor.run {
                    Haptics.light()
                }
            }
        }
    }
    
    var ratingDisplayText: String? {
        guard let value = movie.vote_average else { return nil }
        return "\(value.formatted(.number.precision(.fractionLength(1)))) / 10"
    }
    
    var reviewCountText: String {
        guard let count = movie.vote_count, count > 0 else {
            return "Nessuna recensione disponibile"
        }
        let formatted = count.formatted(.number.grouping(.automatic))
        return count == 1 ? "\(formatted) recensione" : "\(formatted) recensioni"
    }
    
    var providerGroups: [(title: String, providers: [Provider])] {
        let grouped = Dictionary(grouping: movie.providers) { $0.kind }
        let order: [Provider.Kind] = [.flatrate, .rent, .buy]
        return order.compactMap { kind in
            guard let providers = grouped[kind], !providers.isEmpty else { return nil }
            return (availabilityTitle(for: kind), providers.sorted { $0.name < $1.name })
        }
    }
    
    func providerRow(for provider: Provider) -> some View {
        HStack(spacing: 14) {
            providerLogoView(for: provider.logo)
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            
            Text(provider.name)
                .font(.body.weight(.semibold))
                .foregroundStyle(primaryTextColor)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    func providerLogoView(for url: URL?) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure, .empty:
                placeholderLogo
            @unknown default:
                placeholderLogo
            }
        }
    }
    
    var placeholderLogo: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.08))
            Image(systemName: "play.circle.fill")
                .font(.title3)
                .foregroundStyle(secondaryTextColor)
        }
    }
    
    func availabilityTitle(for kind: Provider.Kind) -> String {
        switch kind {
        case .flatrate: return "Incluso nell'abbonamento"
        case .rent: return "Disponibile a noleggio"
        case .buy: return "Disponibile all'acquisto"
        }
    }
    
    var primaryTextColor: Color { .white }
    var secondaryTextColor: Color { .white.opacity(0.7) }
    var sectionBackgroundColor: Color { .white.opacity(0.06) }
    var sectionStrokeColor: Color { .white.opacity(0.12) }
}

// MARK: - Async image helpers
private struct PosterView: View {
    let url: URL?
    
    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
    }
    
    private var placeholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
            Image(systemName: "film")
                .font(.largeTitle)
                .opacity(0.35)
        }
    }
}

private struct BackdropView: View {
    let url: URL?
    
    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        placeholder
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .overlay(Color.black.opacity(0.2))
                    case .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
    }
    
    private var placeholder: some View {
        LinearGradient(
            colors: [.black, .black.opacity(0.6)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
