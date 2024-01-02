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
    
    private var pickRoomPhotoView: some View {
        PickRoomPhotoView(
            pickedRoomPhoto: $viewModel.roomPhoto
        )
    }
    private var pickWallpaperPhotoView: some View {
        PickWallpaperPhotoView(
            pickedWallpaperPhoto: $viewModel.wallpaperPhoto
        )
    }
    private var previewGenerationView: some View {
        PreviewGenerationView(
            viewModel: viewModel
        )
    }
    
    
    var body: some View {
        ZStack {
            switch viewModel.currentTab {
            case .pickRoomPhoto:
                pickRoomPhotoView
            case .pickWallpaperPhoto:
                pickWallpaperPhotoView
            case .preparePreview:
                previewGenerationView
            }
        }
        .frame(maxHeight: .infinity)
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
