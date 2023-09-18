//
//  GalleryGridView.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 14/09/2023.
//

import PhotosUI
import SwiftUI

struct GalleryGridView: View {
    
    let allowsAdding: Bool
    let onItemSelected: ((MediaFile) -> Void)?

    @StateObject
    var viewModel: ViewModel

    private let gridColumns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns) {
                if allowsAdding {
                    AddImageGridItemView {
                        viewModel.addNewMediaFile()
                    }
                    .confirmationDialog(
                        "Room Photo",
                        isPresented: $viewModel.showNewPhotoConfirmationDialog
                    ) {
                        Button {
                            viewModel.takePhoto()
                        } label: {
                            Label("Camera", systemImage: "camera")
                        }

                        Button {
                            viewModel.pickPhotoFromGallery()
                        } label: {
                            Label("Gallery", systemImage: "photo.artframe")
                        }
                    }
                }

                ForEach(viewModel.mediaFiles, id: \.self.id) { mediaFile in
                    ImageGridItemView(imageFilePath: mediaFile.filePath)
                        .onTapGesture {
                            if let onItemSelected {
                                onItemSelected(mediaFile)
                            }
                        }
                        .contextMenu {
                            Button {
                                viewModel.deletePhoto(id: mediaFile.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .padding(8)
        }
        // TODO: switch to PhotosPicker for advanced controls, for now use ImagePicker
//        .photosPicker(
//            isPresented: $viewModel.showPhotosPicker,
//            selection: $viewModel.selectedPhotoItem
//            // TODO: configure
//            // matching: ,
//            // preferredItemEncoding:
//        )

        // MARK: Pick from photos library sheet

        .sheet(isPresented: $viewModel.showPhotosLibrarySheet) {
            let capturedPhotoBinding: Binding<UIImage> = Binding {
                UIImage()
            } set: { capturedPhoto, _ in
                viewModel.onNewPhotoPicked(capturedPhoto)
            }
            ImagePicker(sourceType: .photoLibrary, selectedImage: capturedPhotoBinding)
        }

        // MARK: Photo capture sheet

        .sheet(isPresented: $viewModel.showCameraSheet) {
            let capturedPhotoBinding: Binding<UIImage> = Binding {
                UIImage()
            } set: { capturedPhoto, _ in
                viewModel.onNewPhotoPicked(capturedPhoto)
            }
            ImagePicker(sourceType: .camera, selectedImage: capturedPhotoBinding)
        }
        .onAppear {
            viewModel.loadMediaFiles()
        }
    }
}

struct GalleryGridView_Previews: PreviewProvider {
    static var previews: some View {
        GalleryGridView(
            allowsAdding: true,
            onItemSelected: { mediaFile in
                print("Selected \(mediaFile)")
            },
            viewModel: GalleryGridView.ViewModel(
                fileHelper: FileHelper.shared,
                galleryType: .rooms
            )
        )
    }
}
