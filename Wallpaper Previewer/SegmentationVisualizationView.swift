//
//  SegmentationVisualizationView.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 26/02/2023.
//

import CoreML
import SwiftUI
import Vision

struct SegmentationVisualizationView: View {
    let threshold: Float = 0.5
    let observation: VNObservation

    var body: some View {
        Canvas { context, size in
            guard let featureValueObservation = observation as? VNCoreMLFeatureValueObservation else {
                print("Observation is not VNCoreMLFeatureValueObservation")
                return
            }

            let segmentationMap: MLMultiArray = featureValueObservation.featureValue.multiArrayValue!

            print("Shape: \(segmentationMap.shape)")
            print("Data type: \(segmentationMap.dataType)")

            let segmentationMapWidth = segmentationMap.shape[0].intValue
            let segmentationMapHeight = segmentationMap.shape[1].intValue
            let widthScale = size.width / CGFloat(segmentationMapWidth)
            let heightScale = size.height / CGFloat(segmentationMapHeight)
            print("Segmentation map size: \(segmentationMapWidth)x\(segmentationMapHeight)")
                
            // The stride of a dimension is the number of elements to skip in order to access the next element in that dimension.
            print("Strides: \(segmentationMap.strides)")
            let rowStride = segmentationMap.strides[0].intValue
            print("Row stride: \(rowStride)")

            let segmentationMapPtr = UnsafeMutablePointer<Float32>(OpaquePointer(segmentationMap.dataPointer))

            for row in 0 ..< segmentationMapWidth {
                let rowStartIdx = row * rowStride

                for col in 0 ..< segmentationMapHeight {
                    // "Core ML Survival Guide" claims that pointer access is the fastest option (page 401)
                    // TODO: measure whether this really is the fastest option
                    let score = segmentationMapPtr[rowStartIdx + col]
                    let isWall = score >= self.threshold
                    if !isWall {
                        continue
                    }

                    context.withCGContext { cgContext in
                        cgContext.setFillColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
                        cgContext.fill([
                            CGRect(
                                x: heightScale * CGFloat(col),
                                y: widthScale * CGFloat(row),
                                width: heightScale,
                                height: widthScale
                            )
                        ])
                    }
                }
            }
        }
        .background(.white)
        .border(.red, width: 2)
        .scaledToFill()
    }
}

// struct SegmentationVisualizationView_Previews: PreviewProvider {
//    static var previews: some View {
//        SegmentationVisualizationView()
//    }
// }
