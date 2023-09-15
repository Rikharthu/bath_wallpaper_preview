//
//  FileHelper.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 05/09/2023.
//

import SwiftUI

// TODO: make methods async on IO scheduler
class FileHelper {
    private let synthesisResultsDirectory: URL
    private let photosDirectory: URL
    private let wallpaperTilesDirectory: URL
    // TODO: add directories to save mask image and layout JSON as well
    private let fileManager = FileManager.default
    
    // TODO: use DI
    static let shared: FileHelper = try! create().get()
    
    // TODO: init() make init throw and initiaze directories here
    private init() {
        let documentsDirectory = try! FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
        
        synthesisResultsDirectory = documentsDirectory.appendingPathComponent("Synthesis Results", isDirectory: true)
        photosDirectory = documentsDirectory.appendingPathComponent("Photos", isDirectory: true)
        wallpaperTilesDirectory = documentsDirectory.appendingPathComponent("Wallpaper Tiles", isDirectory: true)
        
        if !fileManager.fileExists(atPath: synthesisResultsDirectory.path) {
            print("Creating synthesis results directory")
            try! fileManager.createDirectory(at: synthesisResultsDirectory, withIntermediateDirectories: true)
        }
        if !fileManager.fileExists(atPath: photosDirectory.path) {
            print("Creating photos directory")
            try! fileManager.createDirectory(at: photosDirectory, withIntermediateDirectories: true)
        }
        if !fileManager.fileExists(atPath: wallpaperTilesDirectory.path) {
            print("Creating wallpaper tiles directory")
            try! fileManager.createDirectory(at: wallpaperTilesDirectory, withIntermediateDirectories: true)
        }
    }
    
    static func create() -> Result<FileHelper, Error> {
        do {
            return try .success(FileHelper())
        } catch {
            print("Could not create FileHelper directores: \(error)")
            return .failure(error)
        }
    }
    
    /// Saves room photo and returns it's new identifier
    func saveRoomPhoto(image: UIImage) -> Result<MediaFile, Error> {
        let id = UUID().uuidString
        let fileName = photoFileNameForId(id)
        
        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            return .failure(FileHelperError.runtimeError("Image does not have JPEG data"))
        }

        let imageFileUrl = photosDirectory.appendingPathComponent(fileName)
        do {
            try imageData.write(to: imageFileUrl)
        } catch {
            return .failure(error)
        }
        
        let mediaFile = MediaFile(id: id, filePath: imageFileUrl.path)
        
        return .success(mediaFile)
    }
    
    func deleteRoomPhoto(id: String) -> Result<Void, Error> {
        let fileName = photoFileNameForId(id)
        let photoFileUrl = photosDirectory.appendingPathComponent(fileName)
        
        do {
            try fileManager.removeItem(at: photoFileUrl)
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    func loadRoomPhoto(id: String) -> Result<UIImage, Error> {
        let filePath = photoFileUrlForId(id).path
        
        guard let image = UIImage(contentsOfFile: filePath) else {
            return .failure(FileHelperError.runtimeError("Could not load image from path \(filePath)"))
        }
        return .success(image)
    }
    
    func photoFilePathForId(_ id: String) -> String {
        return photoFileUrlForId(id).path
    }
    
    func getRoomPhotos() -> Result<[MediaFile], Error> {
        do {
            let photosDirectoryContents = try fileManager.contentsOfDirectory(
                at: photosDirectory,
                includingPropertiesForKeys: nil
            )
            
            // TODO: sort by creation date
            
            let mediaFilesWithCreationDate = try photosDirectoryContents.map { fileUrl in
                let filePath = fileUrl.path
                let id = fileUrl.lastPathComponent.replacing(".jpg", with: "")
                let fileAttributes = try fileManager.attributesOfItem(atPath: filePath)
                let creationDate = fileAttributes[FileAttributeKey.creationDate] as! Date
                return (MediaFile(id: id, filePath: filePath), creationDate)
            }
            
            // Return newer files first
            let mediaFiles = mediaFilesWithCreationDate
                .sorted(by: { $0.1 > $1.1 })
                .map { $0.0 }
            
            return .success(mediaFiles)
        } catch {
            return .failure(error)
        }
    }
    
    private func photoFileNameForId(_ id: String) -> String {
        return "\(id).jpg"
    }
    
    private func photoFileUrlForId(_ id: String) -> URL {
        photosDirectory.appendingPathComponent(photoFileNameForId(id))
    }
}

enum FileHelperError: Error {
    // TODO: add cases for other errors, even FileManager ones (abstract as Other(Error))
    case runtimeError(String)
}
