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
    private var progressLabel: Binding<String> {
        Binding(get: {
            switch viewModel.previewGenerationStatus {
                case .segmentation:
                    return "Segmenting room walls"
                case .layout:
                    return "Estimating room layout"
                case .textureSynthesis:
                    return "Synthesizing wallpaper texture"
                case .assemble:
                    return "Assembling preview"
                case _:
                    return ""
            }
        }, set: {_ in })
    }
    
    var body: some View {
        ZStack(alignment: .center) {
            
            VStack {
                Image(uiImage: viewModel.segmentationImage)
                    .resizable()
                    .frame(width: 256, height: 256)
                ProgressView(
                    label: {
                        Text(progressLabel.wrappedValue)
                    }
                )
                .controlSize(.large)
            }
            
//            switch viewModel.previewGenerationStatus {
//            case .segmentation:
//                Text("Segmentation")
//            case .layout:
//                Text("Layout")
//            case .textureSynthesis:
//                Text("Texture synthesis")
//            case .assemble:
//                Text("Assemble")
//            case .done(let previewMediaFile):
//                Text("Done")
//            case .error(let message):
//                Text("Error: \(message)")
//            }
            
            // TODO: some progress bar
            
            // FIXME: for debug
//            Image(uiImage: viewModel.segmentationImage)
//                .resizable()
//                .scaledToFill()
//                .frame(width: 300, height: 300)
//                .border(Color.red)
//                .padding(12)
                
                
            
        }
        .task {
            await viewModel.generatePreview()
        }
    }
}

struct PreviewGenerationView_Previews: PreviewProvider {
    static var previews: some View {
        var viewModel = PreviewGenerationScreen.ViewModel()
        PreviewGenerationView(
            viewModel: viewModel
        )
    }
}
