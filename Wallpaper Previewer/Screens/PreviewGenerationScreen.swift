//
//  PreviewGenerationScreen.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 15/09/2023.
//

import SwiftUI

struct PreviewGenerationScreen: View {
    @EnvironmentObject
    private var navigationManager: NavigationManager
    @Environment(\.presentationMode)
    private var presentationMode: Binding<PresentationMode>
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
            
            // TODO: when done generating preview, show pinch view with this image and navigation must exit. make it an additional PreviewStep variant
        }
        .sheet(
            item: $viewModel.generatedPreviewFile,
            onDismiss: {
                onPreviewSheetDismissed()
            },
            content: { mediaFile in
                PinchPhotoSheetView(photoFilePath: mediaFile.filePath)
            }
        )
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItemGroup(placement: .topBarLeading) {
                Button {
                    onBackButtonTapped()
                } label: {
                    HStack {
                        Image(systemName: "chevron.backward")
                        Text("Back")
                    }
                }
                // TODO: ideally, according to UX guidelines, we must grant user the possibility to cancel long-running operations.
                .disabled(!viewModel.isBackButtonEnabled)
            }
        }
        
        // TODO: disable manual scrolling, use only progammatic buttons "Next" that become enabled once user is done on current page
    }
    
    private func onPreviewSheetDismissed() {
        // TODO: replace with .home when we introduce that route
        navigationManager.pop()
    }
    
    private func onBackButtonTapped() {
        switch viewModel.currentTab {
        case .pickRoomPhoto:
            presentationMode.wrappedValue.dismiss()
        case .preparePreview:
            navigationManager.pop()
        case _:
            viewModel.returnToPreviousStage()
        }
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
