//
//  SeedData.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 22/09/2023.
//

import Foundation
import UIKit

#if DEBUG

func seedInitialDataIfNeeded() async {
    let didAlreadySeed = UserDefaults.standard.bool(forKey: "did-seed-initial-data")
    if didAlreadySeed {
        print("Initial data has already been seeded")
        return
    }
    
    print("Seeding initial data")
    
    let fileHelper = FileHelper.shared
    
    let roomIndices = [
        4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 20, 22, 24,
        25, 26, 27, 28, 29, 38, 40, 47, 48, 49, 51, 52, 54, 55, 60, 65, 69, 85, 87, 
        100, 105, 109, 131, 132, 135, 137, 139, 141, 166, 192, 196, 250, 258,
        279, 309, 396, 637, 640, 771, 784, 993, 1063, 1076, 1278, 1393, 1449,
        1547, 1583, 1602, 1790, 2023, 1131, 40001, 27, 2
    ]
    for roomIndex in roomIndices {
        let roomPhotoAssetName = "SeedData/RoomPhotos/\(roomIndex)"
        let roomPhotoImage = UIImage(named: roomPhotoAssetName)!
        _ = try! fileHelper.saveRoomPhoto(image: roomPhotoImage).get()
    }
    
    let wallpaperIndices = Array(1...17)
    for wallpaperIndex in wallpaperIndices {
        let wallpaperPhotoAssetName = "SeedData/WallpaperPhotos/wallpaper\(wallpaperIndex)"
        let wallpaperPhotoImage = UIImage(named: wallpaperPhotoAssetName)!
        _ = try! fileHelper.saveWallpaperPhoto(image: wallpaperPhotoImage).get()
    }
    
    // Specifically selected images
    let tileNames = ["grid_tile_1", "grid_tile_2"]
    let roomNames = ["grid_room_1", "grid_room_1_left", "grid_room_2", "grid_room_2_left"]
    
    for tileName in tileNames {
        let wallpaperPhotoAssetName = "SeedData/WallpaperPhotos/\(tileName)"
        let wallpaperPhotoImage = UIImage(named: wallpaperPhotoAssetName)!
        _ = try! fileHelper.saveWallpaperPhoto(image: wallpaperPhotoImage).get()
    }
    for roomName in roomNames {
        let roomPhotoAssetName = "SeedData/RoomPhotos/\(roomName)"
        let roomPhotoImage = UIImage(named: roomPhotoAssetName)!
        _ = try! fileHelper.saveRoomPhoto(image: roomPhotoImage).get()
    }
    
    print("Finished seeding data")
    UserDefaults.standard.set(true, forKey: "did-seed-initial-data")
}

#endif
