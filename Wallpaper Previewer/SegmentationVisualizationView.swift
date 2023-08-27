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
//                    let idx = rowStartIdx + col
//                    let classId = segmentationMap[idx].intValue

//                    let classId = segmentationMap[[row, col] as [NSNumber]]

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

//            let segmentationMapWidth = segmentationMap.shape[2].intValue
//            let segmentationMapHeight = segmentationMap.shape[3].intValue
//
//            let widthScale = size.width / CGFloat(segmentationMapWidth)
//            let heightScale = size.height / CGFloat(segmentationMapHeight)
//
//            print("segmentationMap: \(segmentationMap)")
//            let array = MultiArray<Float>(segmentationMap)
//            print(array.shape)

//            let arrayReshaped = array.reshaped([21, 448, 448])
//            print(arrayReshaped.shape)

            // TODO: to determine class value, use argmax over class dimensions

            // Shape: 1, 21, 448, 448
            // cat: 8

            // TODO: when processing take into account rotation. Photos mask appear to be rotated 90 counter-clockwise

            // TODO: can we get it from model metadata?
            // TODO: can argmax be accelerated with some existing function or processed on multiple threads?
            // TODO: https://github.com/hollance/coreml-survival-guide/blob/4dfcbb97c065726a3da240c55d90b2075959801d/Scripts/deeplab.py#L94-L109

//            let numClasses = 21
//            for rowIndex in 0 ..< segmentationMapHeight {
//                for columnIndex in 0 ..< segmentationMapWidth {
//                    // Determine which class this pixel belongs to
//                    var maxClassId = 0
//                    var maxClassValue = array[0, 0, rowIndex, columnIndex]
//                    for classId in 1 ..< numClasses {
//                        let classValue = array[0, classId, rowIndex, columnIndex]
//                        if classValue > maxClassValue {
//                            maxClassId = classId
//                            maxClassValue = classValue
//                        }
//                    }
//
//                    if maxClassId == 0 {
//                        // It is background, ignore
//                        continue
//                    }
//
//                    // TODO: do we need to apply sigmoid on value?
            ////                    let alpha = segmentationMap[1 * 21 * 448 * classId].doubleValue
//
//                    context.withCGContext { cgContext in
//                        cgContext.setFillColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
//                        cgContext.fill([
//                            CGRect(
//                                x: heightScale * CGFloat(columnIndex),
//                                y: widthScale * CGFloat(rowIndex),
//                                width: heightScale,
//                                height: widthScale
//                            )
//                        ])
//                    }
//                }
//            }
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
