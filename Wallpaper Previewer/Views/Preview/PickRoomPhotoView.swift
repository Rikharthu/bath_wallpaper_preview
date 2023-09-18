//
//  PickRoomPhotoView.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 18/09/2023.
//

import SwiftUI

struct PickRoomPhotoView: View {
    
    @Binding
    var pickedRoomPhoto: MediaFile?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Pick Room Photo")
            Text("Some instructions....")
            GalleryGridView(
                allowsAdding: true,
                onItemSelected: { mediaFile in
                    pickedRoomPhoto = mediaFile
                },
                viewModel: GalleryGridView.ViewModel(
                    fileHelper: FileHelper.shared,
                    galleryType: .rooms
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

struct PickRoomPhotoView_Previews: PreviewProvider {
    static var previews: some View {
        PickRoomPhotoView(
            pickedRoomPhoto: .constant(nil)
        )
    }
}
