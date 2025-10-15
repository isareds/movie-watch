//
//  Glass.swift
//  MovieWatch
//
//  Created by Isacco Rossi on 22/09/25.
//
import SwiftUI

struct GlassCard<Content: View>: View {
    var corner: CGFloat = Design.radius
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(Design.padding)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: corner, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(LinearGradient(colors: [.white.opacity(0.6), .white.opacity(0.15)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.8)
            }
            .shadow(radius: 10, y: 6)
    }
}

struct GlassField<Content: View>: View {
    var corner: CGFloat = 14
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(.vertical, 12).padding(.horizontal, 14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: corner, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(.white.opacity(0.35), lineWidth: 0.8)
            }
    }
}
