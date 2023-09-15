//
//  GalleryScreen.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 13/09/2023.
//

import SwiftUI

struct GalleryScreen: View {
    @State
    private var selectedGalleryType: GalleryType = .rooms
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
                        viewModel: GalleryGridViewModel(
                            fileHelper: FileHelper.shared,
                            galleryType: .rooms
                        )
                    ).tag(GalleryType.rooms)

                    Text("B Tab Content").tag(GalleryType.wallpapers)
                    Text("C Tab Content").tag(GalleryType.previews)
                }
            )
            .animation(.easeOut(duration: 0.2), value: selectedGalleryType)
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }
}

struct GalleryScreen_Previews: PreviewProvider {
    static var previews: some View {
        GalleryScreen()
    }
}
