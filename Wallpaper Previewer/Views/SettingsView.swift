//
//  SettingsView.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 05/10/2023.
//

import SwiftUI

// TODO: start using settings
struct SettingsView: View {
    
   
    @StateObject
    private var settings = Settings.shared
    
    @State
    private var currentWallSegmentationThreshold: Double = 0.5
    @State
    private var currentTextureSynthesisTileSize: Double = Double(Settings.defaultTextureSynthesisTileSize)
    
    @State
    private var currentTextureSynthesisCauchyDispersion: Double = Settings.defaultTextureSynthesisCauchyDispersion
    
    var body: some View {
        Form {
            Section(header: Text("Wall Segmentation")) {
                
                Picker("Model", selection: $settings.wallSegmentationModel){
                    ForEach(Settings.wallSegmentationModels, id: \.self) {
                        Text($0)
                    }
                }
                
                SliderSettingView<Double>(
                    title: "Threshold",
                    label: "Wall segmentation threshold",
                    value: $currentWallSegmentationThreshold,
                    range: 0...1,
                    step: 0.01,
                    onEditingChanged: { isEditing in
                        if !isEditing {
                            settings.wallSegmentationThreshold = currentWallSegmentationThreshold
                        }
                    },
                    valueDisplayFormat: "%.2f"
                )
                
            }
            
            Section(header: Text("Layout Estimation")) {
                
            }
            
            Section(header: Text("Texture Synthesis")) {
                SliderSettingView<Double>(
                    title: "Tile Size",
                    label: "Synthesized wallpaper tile size",
                    value: $currentTextureSynthesisTileSize,
                    range: Double(Settings.minTextureSynthesisTileSize)...Double(Settings.maxTextureSynthesisTileSize),
                    step: 1,
                    onEditingChanged: { isEditing in
                        if !isEditing {
                            settings.textureSynthesisTileSize = Int(currentTextureSynthesisTileSize)
                        }
                    },
                    valueDisplayFormat: "%.0f"
                )
                
                SliderSettingView<Double>(
                    title: "Cauchy Dispersion",
                    label: "Cauchy dispersion",
                    value: $currentTextureSynthesisCauchyDispersion,
                    range: 0...1,
                    step: 0.01,
                    onEditingChanged: { isEditing in
                        if !isEditing {
                            settings.textureSynthesisCauchyDispersion = currentTextureSynthesisCauchyDispersion
                        }
                    },
                    valueDisplayFormat: "%.2f"
                )
            }
        }
        .onAppear {
            currentWallSegmentationThreshold = settings.wallSegmentationThreshold
            currentTextureSynthesisTileSize = Double(settings.textureSynthesisTileSize)
            currentTextureSynthesisCauchyDispersion = settings.textureSynthesisCauchyDispersion
        }
    }
}

#Preview {
    SettingsView()
}
