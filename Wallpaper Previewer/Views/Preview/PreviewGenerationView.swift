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
                case .idle:
                    return "Waiting"
                case .segmentation:
                    return "Segmenting room walls"
                case .layout:
                    return "Estimating room layout"
                case .textureSynthesis:
                    return "Synthesizing wallpaper texture"
                case .assemble:
                    return "Assembling preview"
                case .done(_):
                    return "Opening preview"
                case _:
                    return ""
            }
        }, set: {_ in })
    }
    
    var body: some View {
        ZStack(alignment: .center) {
            ProgressView(
                label: {
                    Text(progressLabel.wrappedValue)
                }
            )
            .controlSize(.large)
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
