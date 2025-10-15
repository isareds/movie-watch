import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct NoisyBackground: View {
    private static let noiseImage: Image = {
        let context = CIContext()
        let filter = CIFilter.randomGenerator()
        let size = 600
        if let output = filter.outputImage?
            .cropped(to: CGRect(x: 0, y: 0, width: size, height: size)),
           let cgImage = context.createCGImage(output, from: output.extent) {
            #if canImport(UIKit)
            let uiImage = UIImage(cgImage: cgImage)
            return Image(uiImage: uiImage)
            #elseif canImport(AppKit)
            let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: size, height: size))
            return Image(nsImage: nsImage)
            #else
            return Image(systemName: "rectangle.fill")
            #endif
        }
        return Image(systemName: "rectangle.fill")
    }()
    
    var body: some View {
        LinearGradient(
            colors: [
                Color.black.opacity(0.95),
                Color.black.opacity(0.9),
                Color.black.opacity(0.85)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(noiseLayer.blendMode(.softLight))
        .overlay(vignette)
        .ignoresSafeArea()
    }
    
    private var noiseLayer: some View {
        NoisyBackground.noiseImage
            .resizable()
            .scaledToFill()
            .opacity(0.18)
    }
    
    private var vignette: some View {
        LinearGradient(
            colors: [
                Color.black.opacity(0.0),
                Color.black.opacity(0.15),
                Color.black.opacity(0.3)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
