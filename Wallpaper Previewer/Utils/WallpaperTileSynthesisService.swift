//
//  WallpaperTileSynthesisService.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 23/09/2023.
//

import Foundation
import UIKit

struct WallpaperTileSynthesisService {
    
    let synthesisSize: Int
    
    init() {
        self.synthesisSize = 320
    }
    
    init(synthesisSize: Int) {
        self.synthesisSize = synthesisSize
    }
    
    // TODO: to handle progress report, can we make it AsyncSequence that returns either current loading status or synthesized image (finished) (using enum)
    func synthesizeWallpaperTile(fromPhoto wallpaperPhoto: UIImage) async -> Result<UIImage, SynthesisError> {
        print("Synthesizing wallpaper tile from photo")
        
        guard let rgbData = wallpaperPhoto.pixelValuesRgba() else {
            return .failure(SynthesisError(message: "Could not extract RGBA data from image"));
        }
        
        // TODO: preprocessing?
        let inputSize = wallpaperPhoto.size
        
        let synthesizedRgbDataCount = synthesisSize * synthesisSize * 4
        
        // TODO: make synthesize_texture return RGBA ImageINfo and use UIImage(fromRgbaImageInfo:) extension
        var synthesizedRgbData = wallpaperPhoto.withUnsafeRgbaImageInfoPointer { imageInfoPtr in
            synthesize_texture(imageInfoPtr, UInt32(synthesisSize))
        }
        
        
        // This constructor copies the data from the buffer
        var array = {
            let buffer = UnsafeBufferPointer(
                start: synthesizedRgbData,
                count: synthesizedRgbDataCount
            )
            return Array(buffer)
        }() 
        // To avoid memory leaks, data allocated in Rust must also be released in Rust
        release_image_buffer(synthesizedRgbData, UInt(synthesizedRgbDataCount))
        // Explicitly set invalid data to null to avoid accidentally using it
        // TODO: better isolate in in closure or function
        // TODO: describe in Dissertation why we are doing that (best practice for unsafe code + source link)
        synthesizedRgbData = nil
        
//        let reconstructedCGImage = array.withUnsafeMutableBytes { arrayBytesPtr in
//            let context = CGContext(
//                data: arrayBytesPtr.baseAddress,
//                // TODO: use generated wallpaper tile size
////                width: Int(wallpaperPhoto.size.width),
////                height: Int(wallpaperPhoto.size.height),
//                width: Self.synthesisSize,
//                height: Self.synthesisSize,
//                bitsPerComponent: 8,
////                bytesPerRow: 4 * Int(wallpaperPhoto.size.width),
//                bytesPerRow: 4 * Self.synthesisSize,
//                space: CGColorSpace(name: CGColorSpace.sRGB)!,
//                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
//            )!
//            return context.makeImage()
//        }! // TODO: error handling if nil
//        
//        let wallpaperTile = UIImage(cgImage: reconstructedCGImage)
        let wallpaperTile = UIImage(fromRgbaArray: array, sized: CGSize(width: synthesisSize, height: synthesisSize))
        
        return .success(wallpaperTile)
    }
}

struct SynthesisError: Error {
    let message: String
}
