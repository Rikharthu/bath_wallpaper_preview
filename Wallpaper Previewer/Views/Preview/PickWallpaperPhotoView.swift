//
//  PickWallpaperPhotoView.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 18/09/2023.
//

import SwiftUI

struct PickWallpaperPhotoView: View {
    
    @Binding
    var pickedWallpaperPhoto: MediaFile?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            InstructionsView(
                title: "Pick Wallpaper Photo",
                subtitle: "Pick or capture photo of the wallpaper you want to apply to the room."
            )
            GalleryGridView(
                allowsAdding: true,
                onItemSelected: { mediaFile in
                    pickedWallpaperPhoto = mediaFile
                },
                viewModel: GalleryGridView.ViewModel(
                    fileHelper: FileHelper.shared,
                    galleryType: .wallpapers
                )
            )
            Spacer()
        }
        .frame(
            minWidth: 0,
            maxWidth: .infinity,
            minHeight: 0,
            maxHeight: .infinity,
            alignment: .topLeading
        )
    }
}

struct PickWallpaperPhotoView_Previews: PreviewProvider {
    static var previews: some View {
        PickWallpaperPhotoView(
            pickedWallpaperPhoto: .constant(nil)
        )
    }
}
