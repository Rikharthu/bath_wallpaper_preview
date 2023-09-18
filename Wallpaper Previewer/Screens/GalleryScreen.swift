//
//  GalleryScreen.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 13/09/2023.
//

import SwiftUI

struct GalleryScreen: View {
    
    @State
    private var zoomedImagePath: String? = nil
    
    @State
    private var selectedGalleryType: GalleryType = .rooms
    
    private var pinchSheetVisibleBinding: Binding<Bool> {
        Binding {
            zoomedImagePath != nil
        } set: { _, _ in
            zoomedImagePath = nil
        }
    }
    
    private var headerTopTitle: String {
        switch selectedGalleryType {
        case .rooms:
            return "4 Rooms"
        case .wallpapers:
            return "21 Wallpapers"
        case .previews:
            return "7 Previews"
        }
    }

    var body: some View {
        VStack {
            GalleryHeaderView(
                mainTitle: "My Gallery",
                topTitle: headerTopTitle,
                selectedTab: $selectedGalleryType
            )

            TabView(
                selection: $selectedGalleryType,
                content: {
                    GalleryGridView(
                        allowsAdding: true,
                        onItemSelected: { mediaFile in
                            zoomedImagePath = mediaFile.filePath
                        },
                        viewModel: GalleryGridView.ViewModel(
                            fileHelper: FileHelper.shared,
                            galleryType: .rooms
                        )
                    ).tag(GalleryType.rooms)
                    
                    GalleryGridView(
                        allowsAdding: true,
                        onItemSelected: { mediaFile in
                            zoomedImagePath = mediaFile.filePath
                        },
                        viewModel: GalleryGridView.ViewModel(
                            fileHelper: FileHelper.shared,
                            galleryType: .wallpapers
                        )
                    ).tag(GalleryType.wallpapers)
                    
                    GalleryGridView(
                        allowsAdding: false,
                        onItemSelected: { mediaFile in
                            zoomedImagePath = mediaFile.filePath
                        },
                        viewModel: GalleryGridView.ViewModel(
                            fileHelper: FileHelper.shared,
                            galleryType: .previews
                        )
                    ).tag(GalleryType.previews)
                }
            )
            .animation(.easeOut(duration: 0.2), value: selectedGalleryType)
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        // MARK: Pinch & zoom sheet

        .sheet(isPresented: pinchSheetVisibleBinding) {
            PinchPhotoSheetView(photoFilePath: self.zoomedImagePath!)
        }
    }
}

struct GalleryScreen_Previews: PreviewProvider {
    static var previews: some View {
        GalleryScreen()
    }
}
