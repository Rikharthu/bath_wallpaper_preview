//
//  MLMultiArray+Utils.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 19/09/2023.
//

import CoreML

extension MLMultiArray {
    public var shapeStrides: [UInt] {
        let shape = self.shape
        var currentStride: UInt = 1
        var strides = [currentStride]
        for s in shape.reversed().dropLast() {
            currentStride *= s.uintValue
            strides.append(currentStride)
        }
        return strides.reversed()
    }
}
