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
    
    let roomIndices = [
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24,
        25, 26, 27, 28, 29, 33, 38, 40, 47, 48, 49, 51, 52, 54, 55, 60, 63, 65, 69, 85, 87, 90,
        91, 100, 102, 105, 109, 131, 132, 135, 137, 139, 141, 165, 166, 188, 192, 196, 206, 215,
        218, 246, 250, 258, 272, 279, 280, 309, 396, 555, 637, 640, 771, 784, 993, 1021, 1063,
        1076, 1278, 1393, 1449, 1511, 1547, 1583, 1602, 1790, 2023
    ]
    
    let fileHelper = FileHelper.shared
    for roomIndex in roomIndices {
        let roomPhotoAssetName = "SeedData/RoomPhotos/\(roomIndex)"
        let roomPhotoImage = UIImage(named: roomPhotoAssetName)!
        _ = try! fileHelper.saveRoomPhoto(image: roomPhotoImage).get()
    }
    
    // TODO: seed initial data from asset directory to FileHelper
    
//    let assetName = "SeedData/RoomLayouts/layout_1"
//    let asset = NSDataAsset(name: assetName, bundle: .main)!
//    let decoder = JSONDecoder()
//    let roomLayout = try! decoder.decode(RoomLayout.self, from: asset.data)
//    print("Decoded room layout: \(roomLayout)")
    
    // Room masks
    
    // Room layouts
    
    // Wallpaper photos
    
    // Wallpaper tiles
    
    // Previews?
    
    print("Finished seeding data")
    UserDefaults.standard.set(true, forKey: "did-seed-initial-data")
}

#endif
