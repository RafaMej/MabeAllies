//
//  Item.swift
//  Enactus2026AITesting
//
//  Created by STEM-CEI on 05/05/26.
//

internal import Foundation
internal import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
