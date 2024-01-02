//
//  Settings.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 05/10/2023.
//

import SwiftUI

// TODO: start using these settings
class Settings: ObservableObject {
    static let shared = Settings()
    
    // MARK: Wall segmentation
    static let wallSegmentationModels = ["DeepLab V3 Plus (MobileOne S3)"]
    
    
    
    @AppStorage("wall_segmentation_threshold")
    var wallSegmentationThreshold = 0.5 {
        didSet {
            // We manually notify subscribers (views) of changes because we can't use default implementation
            // from @Published annotation.
            objectWillChange.send()
        }
    }
    
    @AppStorage("wall_segmentation_model")
    var wallSegmentationModel = Settings.wallSegmentationModels[0] {
        didSet {
            objectWillChange.send()
        }
    }
    
    // MARK: Texture synthesis
    static let defaultTextureSynthesisTileSize = 320
    static let minTextureSynthesisTileSize = 160
    static let maxTextureSynthesisTileSize = 1024
    
    static let defaultTextureSynthesisCauchyDispersion = 1.0
    
    static let defaultTextureSynthesisNearestNeighbors = 50
    static let minTextureSynthesisNearestNeighbors = 1
    static let maxTextureSynthesisNearestNeighbors = 1000
    
    static let defaultTextureSynthesisRandomSampleLocations = 50
    static let minTextureSynthesisRandomSampleLocations = 50
    static let maxTextureSynthesisRandomSampleLocations = 50
    
    @AppStorage("texture_synthesis_tile_size")
    var textureSynthesisTileSize: Int = Settings.defaultTextureSynthesisTileSize {
        didSet {
            objectWillChange.send()
        }
    }
    
    @AppStorage("texture_synthesis_cauchy_dispersion")
    var textureSynthesisCauchyDispersion: Double = Settings.defaultTextureSynthesisCauchyDispersion {
        didSet {
            objectWillChange.send()
        }
    }
}
