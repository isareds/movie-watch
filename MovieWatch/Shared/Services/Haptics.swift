//
//  Haptics.swift
//  MovieWatch
//
//  Created by Isacco Rossi on 30/09/25.
//


import UIKit
import CoreHaptics

enum Haptics {
    static var isAvailable: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        if #available(iOS 13.0, *) {
            return CHHapticEngine.capabilitiesForHardware().supportsHaptics
        } else {
            return false
        }
        #endif
    }

    static func success() {
        guard isAvailable else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func light() {
        guard isAvailable else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
