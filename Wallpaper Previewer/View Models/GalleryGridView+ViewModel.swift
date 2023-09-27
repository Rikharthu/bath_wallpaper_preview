//
//  ViewModel.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 14/09/2023.
//

import PhotosUI
import SwiftUI

extension GalleryGridView {
    
    @MainActor
    class ViewModel: ObservableObject {
        @Published
        var mediaFiles: [MediaFile] = .init()
        @Published
        var showNewPhotoConfirmationDialog: Bool = false
        @Published
        var showCameraSheet: Bool = false
        @Published
        var showPhotosLibrarySheet: Bool = false
        
        private let fileHelper: FileHelper
        private let galleryType: GalleryType
        
        init(fileHelper: FileHelper, galleryType: GalleryType) {
            self.fileHelper = fileHelper
            self.galleryType = galleryType
        }
        
        // TODO: could be async since it uses IO
        func loadMediaFiles() async {
            print("Loading media files")
            switch galleryType {
            case .previews:
                print("TODO: Load previews")
            case .rooms:
                await loadRoomPhotos()
            case .wallpapers:
                await loadWallpaperPhotos()
            }
        }
        
        func addNewMediaFile() {
            print("Adding new media file")
            // TODO: present sheet saying whether it is photo or gallery
            // TODO: handle which type of media file
            showNewPhotoConfirmationDialog = true
        }
        
        func takePhoto() {
            print("Will take new photo")
            // TODO: wallpaper photos must be square
            
            showCameraSheet = true
            
            
        }
        
        func onNewPhotoPicked(_ photoImage: UIImage) async {
            print("New photo has been captured")
            switch galleryType {
            case .rooms:
                await savePickedRoomPhoto(photoImage)
            case .wallpapers:
                await savePickedWallpaperPhoto(photoImage)
            case .previews:
                // TODO
                break
            }
        }
        
        func pickPhotoFromGallery() {
            print("Will pick photo from photos library")
            showPhotosLibrarySheet = true
        }
        
        func deletePhoto(id: String) async {
            switch galleryType {
            case .rooms:
                await deleteRoomPhoto(id: id)
            case .wallpapers:
                await deleteWallpaperPhoto(id: id)
            case .previews:
                // TODO
                break
            }
        }
        
        private func deleteRoomPhoto(id: String) async {
            print("Deleting room photo with id \(id)")
            
            switch fileHelper.deleteRoomPhoto(id: id) {
            case .success(_):
                print("Successfully deleted room photo")
                await loadMediaFiles()
            case .failure(let error):
                print("Could not delete room photo: \(error)")
                // TODO: proper error handling
            }
        }
        
        private func deleteWallpaperPhoto(id: String) async {
            print("Deleting wallpaper photo with id \(id)")
            
            switch fileHelper.deleteWallpaperPhoto(id: id) {
            case .success(_):
                print("Successfully deleted wallpaper photo")
                await loadMediaFiles()
            case .failure(let error):
                print("Could not delete wallpaper photo: \(error)")
                // TODO: proper error handling
            }
        }
        
        private func loadRoomPhotos() async {
            switch fileHelper.getRoomPhotos() {
            case .success(let roomPhotos):
                mediaFiles = roomPhotos
            case .failure(let error):
                print("Error loading room photos: \(error)")
                // TODO: display error to UI
            }
        }
        
        private func loadWallpaperPhotos() async {
            switch fileHelper.getWallpaperPhotos() {
            case .success(let wallpaperPhotos):
                mediaFiles = wallpaperPhotos
            case .failure(let error):
                print("Error loading room photos: \(error)")
                // TODO: display error to UI
            }
        }
        
        private func savePickedRoomPhoto(_ image: UIImage) async {
            // TODO: we won't run inference at this point. Instead we will do it during preview generation, if it is not already cached in corresponding directory
            
            // TODO: probably, its better to be done on some background thread since it involves IO?
            switch fileHelper.saveRoomPhoto(image: image) {
            case .success(_):
                print("Successfully saved picked room photo to app gallery")
                await loadMediaFiles()
            case .failure(let error):
                print("Could not save picked room photo to app gallery: \(error)")
                // TODO: error handling
            }
        }
        
        private func savePickedWallpaperPhoto(_ image: UIImage) async {
            // TODO: we won't run inference at this point. Instead we will do it during preview generation, if it is not already cached in corresponding directory
            
            // TODO: probably, its better to be done on some background thread since it involves IO?
            switch fileHelper.saveWallpaperPhoto(image: image) {
            case .success(_):
                print("Successfully saved picked wallpaper photo to app gallery")
                await loadMediaFiles()
            case .failure(let error):
                print("Could not save picked wallpaper photo to app gallery: \(error)")
                // TODO: error handling
            }
        }
    }
}
