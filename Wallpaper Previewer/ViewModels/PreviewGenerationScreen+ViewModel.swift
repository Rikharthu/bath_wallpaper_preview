//
//  PreviewGenerationScreen+ViewModel.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 18/09/2023.
//

import CoreGraphics
import SwiftUI
import Vision

extension PreviewGenerationScreen {
    enum PreviewGenerationStatus {
        case segmentation
        case layout
        case textureSynthesis
        case assemble
        case done(MediaFile)
        case error(String)
    }
    
    @MainActor
    class ViewModel: ObservableObject {
        @Published
        var previewGenerationStatus: PreviewGenerationStatus = .segmentation
        
        // TODO: switch to state pattern instead, where each step is characterized by an enum
        @Published
        var roomPhoto: MediaFile? {
            didSet {
                print("Room photo has been selected")
                updateCurrentTabIfNeeded()
            }
        }

        @Published
        var wallpaperPhoto: MediaFile? {
            didSet {
                print("Wallpaper photo has been selected")
                updateCurrentTabIfNeeded()
            }
        }
        
        @Published
        var currentTab: PreviewStep = .pickRoomPhoto
        
        // FIXME: for debug
        @Published
        var segmentationImage: UIImage = .init()
        
        private let inferenceHelper = RoomInferenceHelper()
        private let fileHelper = FileHelper.shared
        
        private func updateCurrentTabIfNeeded() {
            if roomPhoto == nil {
                currentTab = .pickRoomPhoto
            } else if wallpaperPhoto == nil {
                currentTab = .pickWallpaperPhoto
            } else {
                currentTab = .preparePreview
            }
        }
        
        func generatePreview() async {
            print("Generating preview...")
            
            // MARK: - Wall segmentation

            previewGenerationStatus = .segmentation
            // TODO: check if we have cached room segmentation for this image, if not: create one
            
            guard let roomPhotoFile = roomPhoto else {
                previewGenerationStatus = .error("Room photo missing")
                return
            }
            
            let segmentationImage: UIImage
            switch await prepareRoomSegmentationMask(roomPhotoFile: roomPhotoFile) {
            case .success(let image):
                print("Successfully prepared room wall segmentation image")
                segmentationImage = image
            case .failure(let error):
                previewGenerationStatus = .error(error.message)
                return
            }
            
            // FIXME: visualization made for debug
            self.segmentationImage = segmentationImage
            
            // MARK: - Layout extraction

            previewGenerationStatus = .layout
            
            let roomPhotoImage: UIImage
            switch fileHelper.loadRoomPhoto(id: roomPhotoFile.id) {
            case .success(let image):
                roomPhotoImage = image
            case .failure(let error):
                // TODO: Handle
                return
            }
            
            let layoutObservations: [VNCoreMLFeatureValueObservation]
            let layoutInferenceResults = await inferenceHelper.extractRoomLayout(roomPhotoImage)
            switch layoutInferenceResults {
            case .success(let observations):
                if observations.count != 4 {
                    fatalError("Unexpected number of layout observations: \(observations.count)")
                }
                layoutObservations = [
                    observations[0] as! VNCoreMLFeatureValueObservation,
                    observations[1] as! VNCoreMLFeatureValueObservation,
                    observations[2] as! VNCoreMLFeatureValueObservation,
                    observations[3] as! VNCoreMLFeatureValueObservation,
                ]
            case .failure(let error):
                print("Layout inference failed: \(error)")
                // TODO: handle
                return
            }
            
            // MARK: Parsing layout results
            let edges = layoutObservations[0]
            guard edges.featureName == "edges" else {
                fatalError("Unexpected edge features name: \"\(edges.featureName)\"")
            }
            
            let corners: VNCoreMLFeatureValueObservation = layoutObservations[1]
            guard corners.featureName == "corners" else {
                fatalError("Unexpected corners features name: \"\(corners.featureName)\"")
            }
            
            let cornersFlip: VNCoreMLFeatureValueObservation = layoutObservations[2]
            guard cornersFlip.featureName == "corners_flip" else {
                fatalError("Unexpected flipped corners features name: \"\(cornersFlip.featureName)\"")
            }
            
            let type: VNCoreMLFeatureValueObservation = layoutObservations[3]
            guard type.featureName == "type" else {
                fatalError("Unexpected type features name: \"\(type.featureName)\"")
            }
            
            
            let edgesArray: MLMultiArray = edges.featureValue.multiArrayValue!
            let cornersArray: MLMultiArray = corners.featureValue.multiArrayValue!
            let cornersFlipArray: MLMultiArray = cornersFlip.featureValue.multiArrayValue!
            let typeArray: MLMultiArray = type.featureValue.multiArrayValue!
            
            // We use our custom extension to compute strides based on shape because the existing `strides` property doesn't always match
            let edgesArrayStrides = edgesArray.shapeStrides
            let edgesArrayInfo = MLMultiArray3DInfo(
                data: UnsafeMutablePointer<Float32>(OpaquePointer(edgesArray.dataPointer)),
                shape: (edgesArray.shape[0].uintValue, edgesArray.shape[1].uintValue, edgesArray.shape[2].uintValue),
                strides: (edgesArrayStrides[0], edgesArrayStrides[1], edgesArrayStrides[2])
            )
            
            let cornersArrayStrides = cornersArray.shapeStrides
            let cornersArrayInfo = MLMultiArray3DInfo(
                data: UnsafeMutablePointer<Float32>(OpaquePointer(cornersArray.dataPointer)),
                shape: (cornersArray.shape[0].uintValue, cornersArray.shape[1].uintValue, cornersArray.shape[2].uintValue),
                strides: (cornersArrayStrides[0], cornersArrayStrides[1], cornersArrayStrides[2])
            )
            
            let cornersFlipArrayStrides = cornersFlipArray.shapeStrides
            let cornersFlipArrayInfo = MLMultiArray3DInfo(
                data: UnsafeMutablePointer<Float32>(OpaquePointer(cornersFlipArray.dataPointer)),
                shape: (cornersFlipArray.shape[0].uintValue, cornersFlipArray.shape[1].uintValue, cornersFlipArray.shape[2].uintValue),
                strides: (cornersFlipArrayStrides[0], cornersFlipArrayStrides[1], cornersFlipArrayStrides[2])
            )
            
            let typeArrayStrides = typeArray.shapeStrides
            let typeArrayInfo = MLMultiArray2DInfo(
                data: UnsafeMutablePointer<Float32>(OpaquePointer(typeArray.dataPointer)),
                shape: (typeArray.shape[0].uintValue, typeArray.shape[1].uintValue),
                strides: (typeArrayStrides[0], typeArrayStrides[1])
            )
            
            var roomLayoutEstimationResults = RoomLayoutEstimationResults(
                edges: edgesArrayInfo,
                corners: cornersArrayInfo,
                corners_flip: cornersFlipArrayInfo,
                type_: typeArrayInfo
            )
            
            let roomLayout = process_room_layout_estimation_results(&roomLayoutEstimationResults).model
            
            
            print("Processed room layout: \(roomLayout)")
            
            switch fileHelper.saveRoomLayout(id: roomPhotoFile.id, roomLayout: roomLayout) {
            case .success(let roomLayoutFile):
                print("Successfully saved room layout data to: \(roomLayoutFile.filePath)")
            case .failure(let error):
                print("Could not save room layout data: \(error)")
                // TODO: return error
            }
           
            
            // TODO: misclassification could be partially resolved by parsing using similar room types, and presenting user multiple candidates for him to select the best result. We're mostly wrong because of incorrect room type.
            
            
            
            
        }
        
        private func prepareRoomSegmentationMask(roomPhotoFile: MediaFile) async -> Result<UIImage, PreviewError> {
            let cachedSegmentationMask = fileHelper.loadRoomMask(id: roomPhotoFile.id)
            if case .success(let imageMask) = cachedSegmentationMask, imageMask != nil {
                print("Loaded cached segmentation mask")
                return .success(imageMask!)
            }
            print("Could not load cached segmentation mask, will perform new inference")
            
            let roomPhotoImage: UIImage
            switch fileHelper.loadRoomPhoto(id: roomPhotoFile.id) {
            case .success(let image):
                roomPhotoImage = image
            case .failure(let error):
                return .failure(PreviewError(message: "Could not load room photo: \(error)"))
            }
            
            let segmentationData: VNObservation
            let segmentationResult = await inferenceHelper.segmentImage(roomPhotoImage)
            switch segmentationResult {
            case .success(let observation):
                print("Received segmentation data")
                segmentationData = observation
            case .failure(let error):
                print("Segmentation failed: \(error)")
                return .failure(PreviewError(message: "Segmentation failed: \(error)"))
            }
            
            guard let featureValueObservation = segmentationData as? VNCoreMLFeatureValueObservation else {
                // TODO: this warrants a fatalError
                print("Observation is not VNCoreMLFeatureValueObservation")
                return .failure(PreviewError(message: "Unexpected segmentation observation data type"))
            }
            let segmentationMap: MLMultiArray = featureValueObservation.featureValue.multiArrayValue!
            
            let segmentationImage = createSegmentationMaskImage(segmentationMap: segmentationMap)
            
            if case .failure(let error) = fileHelper.saveRoomMask(image: segmentationImage, id: roomPhotoFile.id) {
                print("Could not save room mask image: \(error)")
                return .failure(PreviewError(message: "Could not save room mask image: \(error)"))
            }
            
            return .success(segmentationImage)
        }
        
        // TODO: move somewhere else to Utils or VisualizationHelper
        private func createSegmentationMaskImage(segmentationMap: MLMultiArray) -> UIImage {
            let segmentationMapWidth = segmentationMap.shape[0].intValue
            let segmentationMapHeight = segmentationMap.shape[1].intValue
            
            print("Segmentation map size: \(segmentationMapWidth)x\(segmentationMapHeight)")
            // The stride of a dimension is the number of elements to skip in order to access the next element in that dimension.
            print("Strides: \(segmentationMap.strides)")
            let rowStride = segmentationMap.strides[0].intValue
            print("Row stride: \(rowStride)")
            let segmentationMapPtr = UnsafeMutablePointer<Float32>(OpaquePointer(segmentationMap.dataPointer))
            
            let threshold: Float = 0.5
            
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: segmentationMapWidth, height: segmentationMapHeight))
            
            let image = renderer.image { context in
                for row in 0 ..< segmentationMapWidth {
                    let rowStartIdx = row * rowStride

                    for col in 0 ..< segmentationMapHeight {
                        // "Core ML Survival Guide" claims that pointer access is the fastest option (page 401)
                        // TODO: measure whether this really is the fastest option
                        let score = segmentationMapPtr[rowStartIdx + col]
                        if score >= threshold {
                            // Wall
                            context.cgContext.setFillColor(UIColor.white.cgColor)
                        } else {
                            // Background
                            context.cgContext.setFillColor(UIColor.black.cgColor)
                        }

                        let point = CGRect(
                            x: col,
                            y: row,
                            width: 1,
                            height: 1
                        )
                        context.cgContext.fill([point])
                    }
                }
            }
            
            return image
        }
    }
}

extension PreviewGenerationScreen.ViewModel {
    struct PreviewError: Error {
        let message: String
    }
}
