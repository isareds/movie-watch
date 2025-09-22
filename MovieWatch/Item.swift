//
//  Item.swift
//  MovieWatch
//
//  Created by Isacco Rossi on 22/09/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
