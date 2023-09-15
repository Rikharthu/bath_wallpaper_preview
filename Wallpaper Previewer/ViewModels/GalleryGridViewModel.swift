//
//  GalleryGridViewModel.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 14/09/2023.
//

import PhotosUI
import SwiftUI

@MainActor
class GalleryGridViewModel: ObservableObject {
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
    func loadMediaFiles() {
        print("Loading media files")
        switch galleryType {
        case .previews:
            print("TODO: Load previews")
        case .rooms:
            loadRoomPhotos()
        case .wallpapers:
            print("TODO: Load wallpapers")
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
    
    func onNewPhotoPicked(_ photoImage: UIImage) {
        print("New photo has been captured")
        switch galleryType {
        case .rooms:
            savePickedRoomPhoto(photoImage)
        case .wallpapers:
            // TODO: wallpaper photos must be square
            break
        case .previews:
            // TODO
            break
        }
    }
    
    func pickPhotoFromGallery() {
        print("Will pick photo from photos library")
        showPhotosLibrarySheet = true
    }
    
    func deletePhoto(id: String) {
        switch galleryType {
        case .rooms:
            deleteRoomPhoto(id: id)
        case .wallpapers:
            // TODO
            break
        case .previews:
            // TODO
            break
        }
    }
    
    private func deleteRoomPhoto(id: String) {
        print("Deleting room photo with id \(id)")
        
        switch fileHelper.deleteRoomPhoto(id: id) {
        case .success(_):
            print("Successfully deleted room photo")
            loadMediaFiles()
        case .failure(let error):
            print("Could not delete room photo: \(error)")
            // TODO: proper error handling
        }
    }
    
    private func loadRoomPhotos() {
        let result = fileHelper.getRoomPhotos()
        switch result {
        case .success(let roomPhotos):
            mediaFiles = roomPhotos
        case .failure(let error):
            print("Error loading room photos: \(error)")
            // TODO: display error to UI
        }
    }
    
    private func savePickedRoomPhoto(_ image: UIImage) {
        // TODO: we won't run inference at this point. Instead we will do it during preview generation, if it is not already cached in corresponding directory
        
        // TODO: probably, its better to be done on some background thread since it involves IO?
        switch fileHelper.saveRoomPhoto(image: image) {
        case .success(_):
            print("Successfully saved picked room photo to app gallery")
            loadMediaFiles()
        case .failure(let error):
            print("Could not save picked room photo to app gallery: \(error)")
            // TODO: error handling
        }
    }
}
