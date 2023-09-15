//
//  GalleryGridView.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 14/09/2023.
//

import PhotosUI
import SwiftUI

struct GalleryGridView: View {
    @StateObject
    var viewModel: GalleryGridViewModel
    @State
    private var zoomedImagePath: String? = nil

    private var pinchSheetVisibleBinding: Binding<Bool> {
        Binding {
            zoomedImagePath != nil
        } set: { _, _ in
            zoomedImagePath = nil
        }
    }

    private let gridColumns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns) {
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

                ForEach(viewModel.mediaFiles, id: \.self.id) { mediaFile in
                    ImageGridItemView(imageFilePath: mediaFile.filePath)
                        .onTapGesture {
                            // TODO: open Pinch view to see image on click
                            zoomedImagePath = mediaFile.filePath
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
        // MARK: Pinch & zoom sheet
        .sheet(isPresented: pinchSheetVisibleBinding) {
            PinchPhotoSheetView(photoFilePath: self.zoomedImagePath!)
        }
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
            viewModel: GalleryGridViewModel(
                fileHelper: FileHelper.shared,
                galleryType: .rooms
            )
        )
    }
}
