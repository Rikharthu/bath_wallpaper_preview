//
//  PreviewGenerationView.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 18/09/2023.
//

import SwiftUI

struct PreviewGenerationView: View {
    
    @StateObject
    var viewModel: PreviewGenerationScreen.ViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            switch viewModel.previewGenerationStatus {
            case .segmentation:
                Text("Segmentation")
            case .layout:
                Text("Layout")
            case .textureSynthesis:
                Text("Texture synthesis")
            case .assemble:
                Text("Assemble")
            case .done(let previewMediaFile):
                Text("Done")
            case .error(let message):
                Text("Error")
            }
            
            // TODO: some progress bar
            
            // FIXME: for debug
            Image(uiImage: viewModel.segmentationImage)
                .resizable()
                .scaledToFill()
                .frame(width: 300, height: 300)
                .border(Color.red)
                .padding(12)
                
                
            
            Spacer()
        }
        .frame(
            minWidth: 0,
            maxWidth: .infinity,
            minHeight: 0,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .task {
            await viewModel.generatePreview()
        }
    }
}

struct PreviewGenerationView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewGenerationView(
            viewModel: PreviewGenerationScreen.ViewModel()
        )
    }
}
