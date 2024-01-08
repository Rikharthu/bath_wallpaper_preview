//
//  FileHelper.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 05/09/2023.
//

import SwiftUI

// TODO: make methods async on IO scheduler
class FileHelper {
    /// Directory storing raw room photos
    private let roomPhotosDirectory: URL
    /// Directory storing room wall mask images
    private let roomMasksDirectory: URL
    /// Directory storing room layout JSON files
    private let roomLayoutsDirectory: URL
    /// Directory storing raw wallpaper photos
    private let wallpapersDirectory: URL
    /// Directory storing tileable wallpaper images
    private let wallpaperTilesDirectory: URL
    /// Directory storing preview images
    private let previewsDirectory: URL
    
    // TODO: add directories to save mask image and layout JSON as well
    private let fileManager = FileManager.default
    
    // TODO: use DI?
    static let shared: FileHelper = try! create().get()
    
    // TODO: init() make init throw and initialize directories here
    private init() {
        let documentsDirectory = try! FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
        
        previewsDirectory = documentsDirectory.appendingPathComponent("Previews", isDirectory: true)
        roomPhotosDirectory = documentsDirectory.appendingPathComponent("Room Photos", isDirectory: true)
        roomMasksDirectory = documentsDirectory.appendingPathComponent("Room Masks", isDirectory: true)
        roomLayoutsDirectory = documentsDirectory.appendingPathComponent("Room Layouts", isDirectory: true)
        wallpapersDirectory = documentsDirectory.appendingPathComponent("Wallpapers", isDirectory: true)
        wallpaperTilesDirectory = documentsDirectory.appendingPathComponent("Wallpaper Tiles", isDirectory: true)
        
        createDirectoryIfNeeded(previewsDirectory)
        createDirectoryIfNeeded(roomPhotosDirectory)
        createDirectoryIfNeeded(roomMasksDirectory)
        createDirectoryIfNeeded(roomLayoutsDirectory)
        createDirectoryIfNeeded(wallpapersDirectory)
        createDirectoryIfNeeded(wallpaperTilesDirectory)
    }
    
    static func create() -> Result<FileHelper, Error> {
        do {
            return try .success(FileHelper())
        } catch {
            print("Could not create FileHelper directores: \(error)")
            return .failure(error)
        }
    }
    
    private func createDirectoryIfNeeded(_ directoryUrl: URL) {
        if !fileManager.fileExists(atPath: directoryUrl.path) {
            print("Creating directory: \(directoryUrl.path)")
            try! fileManager.createDirectory(at: directoryUrl, withIntermediateDirectories: true)
        }
    }
    
    /// Saves room photo and returns it's new identifier
    func saveRoomPhoto(image: UIImage) -> Result<MediaFile, Error> {
        return saveImageToDirectory(image: image, directoryUrl: roomPhotosDirectory)
    }
    
    func deleteRoomPhoto(id: String) -> Result<Void, Error> {
        switch deleteImageFromDirectoryIfExists(imageId: id, directoryUrl: roomPhotosDirectory) {
        case .success(true):
            print("Successfully deleted wallpaper photo: \(id)")
        case .success(false):
            print("Wallpeper photo with id \(id) does not exist")
            return .success(())
        case .failure(let error):
            return .failure(error)
        }
        
        // Also delete room mask and layout files if those exist
        switch deleteImageFromDirectoryIfExists(imageId: id, directoryUrl: roomMasksDirectory) {
        case .success(let deleted):
            print("Deleted room mask \(id): \(deleted)")
        case .failure(let error):
            return .failure(error)
        }
        
        switch deleteJsonFileFromDirectoryIfExists(fileId: id, directoryUrl: roomLayoutsDirectory) {
        case .success(let deleted):
            print("Deleted room layout \(id): \(deleted)")
            return .success(())
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func loadRoomPhoto(id: String) -> Result<UIImage, Error> {
        let filePath = roomPhotoFileUrlForId(id).path
        
        guard let image = UIImage(contentsOfFile: filePath) else {
            return .failure(FileHelperError.runtimeError("Could not load image from path \(filePath)"))
        }
        return .success(image)
    }
    
    func photoFilePathForId(_ id: String) -> String {
        return roomPhotoFileUrlForId(id).path
    }
    
    func getRoomPhotos() -> Result<[MediaFile], Error> {
        return getMediaFiles(fromDirectory: roomPhotosDirectory)
    }
    
    func saveWallpaperPhoto(image: UIImage) -> Result<MediaFile, Error> {
        return saveImageToDirectory(image: image, directoryUrl: wallpapersDirectory)
    }
    
    func loadWallpaperPhoto(id: String) -> Result<UIImage, Error> {
        let filePath = wallpaperPhotoUrlForId(id).path
        guard let image = UIImage(contentsOfFile: filePath) else {
            return .failure(FileHelperError.runtimeError("Could not load image from path \(filePath)"))
        }
        return .success(image)
    }
    
    func deleteWallpaperPhoto(id: String) -> Result<Void, Error> {
        switch deleteImageFromDirectoryIfExists(imageId: id, directoryUrl: wallpapersDirectory) {
        case .success(true):
            print("Successfully deleted wallpaper photo: \(id)")
        case .success(false):
            print("Wallpeper photo with id \(id) does not exist")
            return .success(())
        case .failure(let error):
            return .failure(error)
        }
        
        // Also delete wallpaper tiles if those exist
        switch deleteImageFromDirectoryIfExists(imageId: id, directoryUrl: wallpaperTilesDirectory) {
        case .success(let deleted):
            print("Deleted wallpaper tile \(id): \(deleted)")
            return .success(())
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func getWallpaperPhotos() -> Result<[MediaFile], Error> {
        return getMediaFiles(fromDirectory: wallpapersDirectory)
    }
    
    func saveWallpaperTile(image: UIImage, id: String) -> Result<MediaFile, Error> {
        return saveImageToDirectory(image: image, id: id, directoryUrl: wallpaperTilesDirectory)
    }
    
    func loadWallpaperTile(id: String) -> Result<UIImage?, Error> {
        let filePath = wallpaperTileUrlForId(id).path
        
        if !fileManager.fileExists(atPath: filePath) {
            // TODO: ideally we would handle non-existend mask as specific error enum variant
            return .success(nil)
        }
        
        guard let image = UIImage(contentsOfFile: filePath) else {
            return .failure(FileHelperError.runtimeError("Could not load image from path \(filePath)"))
        }
        return .success(image)
    }
    
    func getPreviewImages() -> Result<[MediaFile], Error> {
        return getMediaFiles(fromDirectory: previewsDirectory)
    }
    
    func savePreviewImage(image: UIImage) -> Result<MediaFile, Error> {
        return saveImageToDirectory(image: image, directoryUrl: previewsDirectory)
    }
    
    func deletePreviewImage(id: String) -> Result<Void, Error> {
        switch deleteImageFromDirectoryIfExists(imageId: id, directoryUrl: previewsDirectory) {
        case .success(true):
            print("Successfully deleted preview image: \(id)")
            return .success(())
        case .success(false):
            print("Preview image with id \(id) does not exist")
            return .success(())
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func getRoomMasksPhotos() -> Result<[MediaFile], Error> {
        return getMediaFiles(fromDirectory: roomMasksDirectory)
    }
    
    func saveRoomMask(image: UIImage, id: String) -> Result<MediaFile, Error> {
        return saveImageToDirectory(image: image, id: id, directoryUrl: roomMasksDirectory)
    }
    
    func loadRoomMask(id: String) -> Result<UIImage?, Error> {
        let filePath = roomMaskFileUrlForId(id).path
        
        if !fileManager.fileExists(atPath: filePath) {
            // TODO: ideally we would handle non-existend mask as specific error enum variant
            return .success(nil)
        }
        
        guard let image = UIImage(contentsOfFile: filePath) else {
            return .failure(FileHelperError.runtimeError("Could not load image from path \(filePath)"))
        }
        return .success(image)
    }
    
    func saveRoomLayout(id: String, roomLayout: RoomLayout) -> Result<MediaFile, Error> {
        let fileUrl = roomLayoutFileUrlForId(id)
        
        do {
            let encodedRoomLayout = try JSONEncoder().encode(roomLayout)
            try encodedRoomLayout.write(to: fileUrl)
        } catch {
            return .failure(error)
        }
        
        let mediaFile = MediaFile(id: id, filePath: fileUrl.path)
        return .success(mediaFile)
    }
    
    func loadRoomLayout(id: String) -> Result<RoomLayout?, Error> {
        let fileUrl = roomLayoutFileUrlForId(id)
        
        if !fileManager.fileExists(atPath: fileUrl.path) {
            // TODO: ideally we would handle non-existend mask as specific error enum variant
            return .success(nil)
        }
        
        do {
            let jsonData = try Data(contentsOf: fileUrl)
            let roomLayout = try JSONDecoder().decode(RoomLayout.self, from: jsonData)
            return .success(roomLayout)
        } catch {
            return .failure(error)
        }
    }
    
    private func saveImageToDirectory(image: UIImage, id: String, directoryUrl: URL) -> Result<MediaFile, Error> {
        let fileName = imageFileNameForId(id)
        
        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            return .failure(FileHelperError.runtimeError("Image does not have JPEG data"))
        }
        
        let imageFileUrl = directoryUrl.appendingPathComponent(fileName)
        do {
            try imageData.write(to: imageFileUrl)
        } catch {
            return .failure(error)
        }
        
        let mediaFile = MediaFile(id: id, filePath: imageFileUrl.path)
        
        return .success(mediaFile)
    }
    
    private func saveImageToDirectory(image: UIImage, directoryUrl: URL) -> Result<MediaFile, Error> {
        let id = UUID().uuidString
        return saveImageToDirectory(image: image, id: id, directoryUrl: directoryUrl)
    }
    
    
    private func deleteImageFromDirectoryIfExists(imageId: String, directoryUrl: URL) -> Result<Bool, Error> {
        let fileName = imageFileNameForId(imageId)
        let imageFileUrl = directoryUrl.appendingPathComponent(fileName)
        
        if fileManager.fileExists(atPath: imageFileUrl.path) {
            do {
                try fileManager.removeItem(at: imageFileUrl)
                return .success(true)
            } catch {
                return .failure(error)
            }
        } else {
            return .success(false)
        }
    }
    
    private func deleteJsonFileFromDirectoryIfExists(fileId: String, directoryUrl: URL) -> Result<Bool, Error> {
        let fileName = jsonFileNameForId(fileId)
        let jsonFileUrl = directoryUrl.appendingPathComponent(fileName)
        
        if fileManager.fileExists(atPath: jsonFileUrl.path) {
            do {
                try fileManager.removeItem(at: jsonFileUrl)
                return .success(true)
            } catch {
                return .failure(error)
            }
        } else {
            return .success(false)
        }
    }
    
    private func getMediaFiles(fromDirectory directory: URL) -> Result<[MediaFile], Error> {
        do {
            let directoryContents = try fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: nil
            )
            
            let mediaFilesWithCreationDate = try directoryContents.map { fileUrl in
                let filePath = fileUrl.path
                let id = fileUrl.lastPathComponent.replacing(".jpg", with: "")
                let fileAttributes = try fileManager.attributesOfItem(atPath: filePath)
                let creationDate = fileAttributes[FileAttributeKey.creationDate] as! Date
                return (MediaFile(id: id, filePath: filePath), creationDate)
            }
            
            let mediaFiles = mediaFilesWithCreationDate
                .sorted(by: { $0.1 > $1.1 })
                .map { $0.0 }
            
            return .success(mediaFiles)
        } catch {
            return .failure(error)
        }
    }
    
    private func roomPhotoFileUrlForId(_ id: String) -> URL {
        roomPhotosDirectory.appendingPathComponent(imageFileNameForId(id))
    }
    
    private func roomMaskFileUrlForId(_ id: String) -> URL {
        roomMasksDirectory.appendingPathComponent(imageFileNameForId(id))
    }
    
    private func roomLayoutFileUrlForId(_ id: String) -> URL {
        roomLayoutsDirectory.appendingPathComponent(jsonFileNameForId(id))
    }
    
    private func wallpaperPhotoUrlForId(_ id: String) -> URL {
        wallpapersDirectory.appendingPathComponent(imageFileNameForId(id))
    }
    
    private func wallpaperTileUrlForId(_ id: String) -> URL {
        wallpaperTilesDirectory.appendingPathComponent(imageFileNameForId(id))
    }
    
    private func previewFileUrlForId(_ id: String) -> URL {
        previewsDirectory.appendingPathComponent(imageFileNameForId(id))
    }
    
    private func jsonFileNameForId(_ id: String) -> String {
        return "\(id).json"
    }
    
    private func imageFileNameForId(_ id: String) -> String {
        return "\(id).jpg"
    }
}

enum FileHelperError: Error {
    // TODO: add cases for other errors, even FileManager ones (abstract as Other(Error))
    case runtimeError(String)
}
