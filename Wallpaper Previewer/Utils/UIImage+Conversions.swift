//
//  UIImage+Conversions.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 03/02/2023.
//

import CoreGraphics
import Foundation
import UIKit

extension UIImage {
    func pixelValuesRgba() -> [UInt8]? {
        guard let cgImage = cgImage else {
            print("Could not get CGImage")
            return nil
        }
        
        // Although we are interested in RGB image, we have to use RGBA here, because
        // there is no RGB without alpha CoreGraphics:
        // https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/dq_context/dq_context.html#//apple_ref/doc/uid/TP30001066-CH203-BCIBHHBB
        // That is, we can't work directly with 24-bit (3x8) packed pixels, but we can ignore alpha channel
        // by passing noneSkipLast bitmap info when create CoreGraphics context
        
        let totalBytes = Int(size.width * size.height * 4)
        var intensities = [UInt8](repeating: 0, count: totalBytes)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let context = CGContext(
            data: &intensities,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: 4 * Int(size.width),
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        )
        
        guard let context = context else {
            print("Could not create CGContext")
            return nil
        }
        context.draw(
            cgImage,
            in: CGRect(x: 0, y: 0, width: size.width, height: size.height)
        )
        
        return intensities
    }
}
