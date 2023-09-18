//
//  ContentViewModel.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 26/08/2023.
//

import SwiftUI
import CoreML
import Vision

@MainActor
class ContentViewModel: ObservableObject {
    
    private var roomLayoutModel: VNCoreMLModel? = nil
    private var wallSegmentationModel: VNCoreMLModel? = nil
    
    init() {
        Task(priority: .medium) {
            await self.initializeModels()
        }
    }
    
    func initializeModels() async {
        print("Initializing models")
        self.roomLayoutModel = createRoomLayoutEstimationModel()
        // TODO: WallSegmentationModel
    }
    
    func processRoomImage(_ image: UIImage) async {
        let estimateLayoutRequest = VNCoreMLRequest(
            model: self.roomLayoutModel!
        ) { [weak self] request, error in
            guard let self = self else {
                return
            }
            
            if let error {
                print("Error performing room layout estimation: \(error)")
                return
            }
            
            let results: [VNObservation] = request.results!
            print("Number of results: \(results.count)")
            
            self.handleRoomLayoutEstimationResults(results)
//            guard let result: VNObservation = request.results?.first else {
//                print("Result was empty")
//                return
//            }
            
            // TODO: handle
            
            
            print("Esimated room layout")
        }
        
        // Same option as the model was trained on
        estimateLayoutRequest.imageCropAndScaleOption = .scaleFill
        
        let sourceImageOrientation = image.imageOrientation
        let sourceImageScale = image.scale
        print("Image orientation: \(sourceImageOrientation)")
        print("Image scale: \(sourceImageScale)")

        let cgImageOrientation = CGImagePropertyOrientation(sourceImageOrientation)
        print("Input image orientation: \(cgImageOrientation), is up: \(cgImageOrientation == .up)")
        
        let handler = VNImageRequestHandler(
            cgImage: image.cgImage!,
            orientation: cgImageOrientation,
            options: [:]
        )
        
        // TODO: it appears, that we can pass multiple requests. Combine it with wall segmentation!
        try! handler.perform([estimateLayoutRequest])
    }
    
    func handleRoomLayoutEstimationResults(_ results: [VNObservation]) {
        let edges = results[0] as! VNCoreMLFeatureValueObservation
        guard edges.featureName == "edges" else {
            fatalError("Unexpected edge features name: \"\(edges.featureName)\"")
        }
        
        let corners: VNCoreMLFeatureValueObservation = results[1] as! VNCoreMLFeatureValueObservation
        guard corners.featureName == "corners" else {
            fatalError("Unexpected corners features name: \"\(corners.featureName)\"")
        }
        
        let cornersFlip: VNCoreMLFeatureValueObservation = results[2] as! VNCoreMLFeatureValueObservation
        guard cornersFlip.featureName == "corners_flip" else {
            fatalError("Unexpected flipped corners features name: \"\(cornersFlip.featureName)\"")
        }
        
        let type: VNCoreMLFeatureValueObservation = results[3] as!VNCoreMLFeatureValueObservation
        guard type.featureName == "type" else {
            fatalError("Unexpected type features name: \"\(type.featureName)\"")
        }
        
        let edgesArray: MLMultiArray = edges.featureValue.multiArrayValue!
        let cornersArray: MLMultiArray = corners.featureValue.multiArrayValue!
        let cornersFlipArray: MLMultiArray = cornersFlip.featureValue.multiArrayValue!
        let typeArray: MLMultiArray = type.featureValue.multiArrayValue!
        print("Edges array shape: \(edgesArray.shape), strides: \(edgesArray.strides)")
        print("Corners array shape: \(cornersArray.shape), strides: \(cornersArray.strides)")
        print("Flipped corners array shape: \(cornersFlipArray.shape), strides: \(cornersFlipArray.strides)")
        print("Type array shape: \(typeArray.shape), strides: \(typeArray.strides)")
        
        // TODO: extract this conversion code to Utils / Extensions
        let edgesArrayInfo = MLMultiArray3DInfo(
            data: UnsafeMutablePointer<Float32>(OpaquePointer(edgesArray.dataPointer)),
            shape: (UInt(edgesArray.shape[0]), UInt(edgesArray.shape[1]), UInt(edgesArray.shape[2])),
            strides: (UInt(edgesArray.strides[0]), UInt(edgesArray.strides[1]), UInt(edgesArray.strides[2]))
        )
        let cornersArrayInfo = MLMultiArray3DInfo(
            data: UnsafeMutablePointer<Float32>(OpaquePointer(cornersArray.dataPointer)),
            shape: (UInt(cornersArray.shape[0]), UInt(cornersArray.shape[1]), UInt(cornersArray.shape[2])),
            strides: (UInt(cornersArray.strides[0]), UInt(cornersArray.strides[1]), UInt(cornersArray.strides[2]))
        )
        let cornersFlipArrayInfo = MLMultiArray3DInfo(
            data: UnsafeMutablePointer<Float32>(OpaquePointer(cornersFlipArray.dataPointer)),
            shape: (UInt(cornersFlipArray.shape[0]), UInt(cornersFlipArray.shape[1]), UInt(cornersFlipArray.shape[2])),
            strides: (UInt(cornersFlipArray.strides[0]), UInt(cornersFlipArray.strides[1]), UInt(cornersFlipArray.strides[2]))
        )
        let typeArrayInfo = MLMultiArray2DInfo(
            data: UnsafeMutablePointer<Float32>(OpaquePointer(typeArray.dataPointer)),
            shape: (UInt(typeArray.shape[0]), UInt(typeArray.shape[1])),
            strides: (UInt(typeArray.strides[0]), UInt(typeArray.strides[1]))
        )
        var roomLayoutEstimationResults = RoomLayoutEstimationResults(
            edges: edgesArrayInfo,
            corners: cornersArrayInfo,
            corners_flip: cornersFlipArrayInfo,
            type_: typeArrayInfo
        )
//        process_room_layout_estimation_results(&roomLayoutEstimationResults)
        
        
//        let array = try! MLMultiArray(shape: [3, 4], dataType: .float32)
//        let ptr = UnsafeMutablePointer<Float32>(OpaquePointer(array.dataPointer))
//        let rowStride = array.strides[0].intValue
//        let columnStride = array.strides[1].intValue
//        let row = 1;
//        let column = 3;
//        let pos = row * rowStride + column * columnStride;
//        ptr[pos] = 42.0;
//
//        var segmentationMap = SegmentationMap(
//            data: ptr,
//            height: 3,
//            width: 4,
//            strides: (UInt(rowStride), UInt(columnStride))
//        )
        
    }
}
