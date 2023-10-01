//
//  WallpaperSynthesisHelper.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 23/09/2023.
//

import Foundation
import UIKit

final class WallpaperSynthesisHelper {
    
    private static let synthesisSize: Int = 320
    
    // TODO: to handle progress report, can we make it AsyncSequence that returns either current loading status or synthesized image (finished) (using enum)
    func synthesizeWallpaperTile(fromPhoto wallpaperPhoto: UIImage) async -> Result<UIImage, SynthesisError> {
        print("Synthesizing wallpaper tile from photo")
        
        guard let rgbData = wallpaperPhoto.pixelValuesRgba() else {
            return .failure(SynthesisError(message: "Could not extract RGBA data from image"));
        }
        
        // TODO: preprocessing?
        let inputSize = wallpaperPhoto.size
        
        let synthesizedRgbDataCount = Self.synthesisSize * Self.synthesisSize * 4 // Hardocded in Rust code for now
        
        var synthesizedRgbData = wallpaperPhoto.withUnsafeRgbaImageInfoPointer { imageInfoPtr in
            synthesize_texture(imageInfoPtr, UInt32(Self.synthesisSize))
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
        let wallpaperTile = UIImage(fromRgbaArray: array, sized: CGSize(width: Self.synthesisSize, height: Self.synthesisSize))
        
        return .success(wallpaperTile)
    }
}

struct SynthesisError: Error {
    let message: String
}
