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
                        progressSection
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
                        Label("Elimina", systemImage: "trash")
                    }
                    .tint(Color.red.opacity(0.9))
                    
                    Button {
                        refreshMovie()
                    } label: {
                        Label("Aggiorna", systemImage: "arrow.clockwise")
                    }
                    .tint(Color.white.opacity(0.9))
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
            HStack(alignment: .top, spacing: 15) {
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
                            Text(verbatim: String(year))
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
    var progressSection: some View {
        detailSection(alignment: .leading, spacing: 16) {
            Text("Progresso")
                .font(.headline)
                .foregroundStyle(primaryTextColor)
            
            let runtime: Int = movie.runtime
            if runtime > 0 {
                VStack(alignment: .leading, spacing: 12) {
                    Slider(
                        value: progressBinding(for: runtime),
                        in: 0...Double(runtime),
                        step: 1
                    ) {
                        Text("Punto raggiunto")
                    }
                    .tint(.green.opacity(0.8))
                    
                    HStack {
                        Text("Avanzamento: \(formattedMinutes(movie.watchPosition))")
                            .font(.subheadline)
                            .foregroundStyle(primaryTextColor)
                        Spacer()
                        Text("Durata: \(formattedMinutes(runtime))")
                            .font(.subheadline)
                            .foregroundStyle(secondaryTextColor)
                    }
                }
            } else {
                Text("Durata non disponibile. Aggiorna i dati per recuperarla da TMDB.")
                    .font(.subheadline)
                    .foregroundStyle(secondaryTextColor)
            }
        }
    }
    
    @ViewBuilder
    var availabilitySection: some View {
        if providerGroups.isEmpty {
            detailSection(alignment: .leading, spacing: 12) {
                Text("Disponibile su")
                    .font(.headline)
                    .foregroundStyle(primaryTextColor)
                Text("Nessuna piattaforma segnalata al momento.")
                    .font(.subheadline)
                    .foregroundStyle(secondaryTextColor)
            }
        } else {
            ForEach(providerGroups) { group in
                detailSection(alignment: .leading, spacing: 16) {
                    Text(group.title)
                        .font(.headline)
                        .foregroundStyle(primaryTextColor)
                    providerList(for: group.providers)
                }
            }
        }
    }
}

// MARK: - Subviews & Helpers
private extension MovieDetailView {
    @ViewBuilder
    var ratingSummary: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let ratingText = ratingDisplayText {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.title3)
                    Text(ratingText)
                        .font(.title3.bold())
                        .foregroundStyle(primaryTextColor)
                }
            }
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
            } catch {
                print("Refresh error:", error.localizedDescription)
            }
            await fireLightHaptic()
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
    
    var providerGroups: [ProviderGroup] {
        Provider.Kind.allCases.compactMap { kind in
            let providers = movie.providers
                .filter { $0.kind == kind }
                .sorted { $0.name < $1.name }
            guard !providers.isEmpty else { return nil }
            return ProviderGroup(kind: kind, providers: providers)
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
            if let image = phase.image {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                placeholderLogo
            }
        }
    }
    
    func providerList(for providers: [Provider]) -> some View {
        LazyVStack(spacing: 12) {
            ForEach(Array(providers.enumerated()), id: \.element.id) { index, provider in
                providerRow(for: provider)
                if index < providers.count - 1 {
                    Divider()
                        .overlay(sectionStrokeColor.opacity(0.6))
                }
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
    
    var primaryTextColor: Color { .white }
    var secondaryTextColor: Color { .white.opacity(0.7) }
    var sectionBackgroundColor: Color { .white.opacity(0.06) }
    var sectionStrokeColor: Color { .white.opacity(0.12) }
    
    func progressBinding(for runtime: Int) -> Binding<Double> {
        Binding(
            get: { Double(min(movie.watchPosition, runtime)) },
            set: { value in
                let minutes = Int(value.rounded())
                movie.watchPosition = max(0, min(minutes, runtime))
            }
        )
    }
    
    func formattedMinutes(_ minutes: Int) -> String {
        guard minutes > 0 else { return "0m" }
        let hours = minutes / 60
        let remainder = minutes % 60
        if hours > 0 {
            if remainder > 0 {
                return "\(hours)h \(remainder)m"
            } else {
                return "\(hours)h"
            }
        }
        return "\(minutes)m"
    }
    
    @MainActor
    func fireLightHaptic() {
        Haptics.light()
    }
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

private struct ProviderGroup: Identifiable {
    let kind: Provider.Kind
    let providers: [Provider]
    
    var id: Provider.Kind { kind }
    var title: String { kind.availabilityTitle }
}

private extension Provider.Kind {
    var availabilityTitle: String {
        switch self {
        case .flatrate: return "Incluso nell'abbonamento"
        case .rent: return "Disponibile a noleggio"
        case .buy: return "Disponibile all'acquisto"
        }
    }
}
