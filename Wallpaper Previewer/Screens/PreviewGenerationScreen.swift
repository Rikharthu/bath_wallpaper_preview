//
//  PreviewGenerationScreen.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 15/09/2023.
//

import SwiftUI

struct PreviewGenerationScreen: View {
    
    @StateObject
    private var viewModel = ViewModel()
    // TODO: launch preview creation flow
    //   1. Select room
    //   2. Load or generate room walls mask, display to user on top of image and layout
    //   3. Load or generate room layout, display to user on top of selected image
    //  4. Select wallpaper
    //  5. Load or generate tile, display some tiled examples as image
    //  6. Assemble everything into preview
    
    
    var body: some View {
        // TODO: use TabView for multi-step flow
        TabView(selection: $viewModel.currentTab) {
            // TODO: each page might have its own ViewModel that exposes completion status (can switch to next tab)
            PickRoomPhotoView(
                pickedRoomPhoto: $viewModel.roomPhoto
            ).tag(PreviewStep.pickRoomPhoto)
            
            PickWallpaperPhotoView(
                pickedWallpaperPhoto: $viewModel.wallpaperPhoto
            ).tag(PreviewStep.pickWallpaperPhoto)
            
            PreviewGenerationView(
                viewModel: viewModel
            ).tag(PreviewStep.preparePreview)
            
            
        }
        
        // TODO: disable manual scrolling, use only progammatic buttons "Next" that become enabled once user is done on current page
    }
}

// TODO: move to Models
enum PreviewStep {
    case pickRoomPhoto
    case pickWallpaperPhoto
    case preparePreview
}

struct PreviewGenerationScreen_Previews: PreviewProvider {
    static var previews: some View {
        PreviewGenerationScreen()
    }
}