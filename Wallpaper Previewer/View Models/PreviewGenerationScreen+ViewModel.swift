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
        case idle
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
        var previewGenerationStatus: PreviewGenerationStatus {
            didSet {
                updateBackButtonStatus()
            }
        }
        
        @Published
        var isBackButtonEnabled: Bool = true
        
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
        private let wallpaperSynthesisHelper = WallpaperSynthesisHelper()
        
        init() {
            previewGenerationStatus = .idle
        }
        
        private func updateCurrentTabIfNeeded() {
            if roomPhoto == nil {
                currentTab = .pickRoomPhoto
            } else if wallpaperPhoto == nil {
                currentTab = .pickWallpaperPhoto
            } else {
                currentTab = .preparePreview
            }
        }
        
        private func updateBackButtonStatus() {
            switch previewGenerationStatus {
            case .idle, .error(_), .done(_):
                isBackButtonEnabled = true
            case _:
                isBackButtonEnabled = false
            }
        }
        
        func returnToPreviousStage() {
            switch currentTab {
            case .pickRoomPhoto:
                // Do nothing
                break
            case .pickWallpaperPhoto:
                roomPhoto = nil
                wallpaperPhoto = nil
            case .preparePreview:
                wallpaperPhoto = nil
            }
            updateCurrentTabIfNeeded()
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
            guard let wallpaperPhotoFile = wallpaperPhoto else {
                previewGenerationStatus = .error("Wallpaper photo missing")
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
            print("Prepared segmentation image size: \(segmentationImage.size)")
            
            // MARK: - Layout extraction

            previewGenerationStatus = .layout
            
            let roomLayout: RoomLayout
            switch await prepareRoomLayout(roomPhotoFile: roomPhotoFile) {
            case .success(let layout):
                roomLayout = layout
                print("Successfully prepared room layout: \(roomLayout)")
            case .failure(let error):
                print("Could not prepare room layout: \(error)")
                previewGenerationStatus = .error(error.message)
                return
            }
           
            // MARK: - Texture synthesis

            previewGenerationStatus = .textureSynthesis
            
            let wallpaperTile: UIImage
            switch await prepareWallpaperTile(wallpaperPhotoFile: wallpaperPhotoFile) {
            case .success(let tile):
                wallpaperTile = tile
            case .failure(let error):
                print("Could not prepare wallpaper tile: \(error)")
                previewGenerationStatus = .error("Could not prepare wallpaper tile: \(error)")
                return
            }
               
            // MARK: - Assemble preview

            previewGenerationStatus = .assemble
            
            // TODO: avoid reading room and wallpaper photos multiple times, load it only once and pass it in prepare methods
            let roomPhoto: UIImage
            switch fileHelper.loadRoomPhoto(id: roomPhotoFile.id) {
            case .success(let image):
                roomPhoto = image
            case .failure(let error):
                print("Could not load room photo: \(error)")
                previewGenerationStatus = .error("Could not load room photo: \(error)")
                return
            }
            
            let previewImage: UIImage
            switch await prepareWallpaperPreview(
                roomPhoto: roomPhoto,
                roomWallMask: segmentationImage,
                roomLayout: roomLayout,
                wallpaperTile: wallpaperTile
            ) {
            case .success(let image):
                previewImage = image
            case .failure(let error):
                print("Could not prepare preview: \(error)")
                previewGenerationStatus = .error("Could not prepare preview: \(error)")
                return
            }
            
            
            
            // MARK: Done
            // TODO: implement
            previewGenerationStatus = .done(MediaFile(id: "1", filePath: "1.jpg"))
            
            
            // TODO: open pinch view after some delay so that user sees "Done" text
            // TODO: edit navigation backstack so that "back" button returns to flow start (resetting state)
        }
        
        private func prepareWallpaperPreview(
            roomPhoto: UIImage,
            roomWallMask: UIImage,
            roomLayout: RoomLayout,
            wallpaperTile: UIImage
        ) async -> Result<UIImage, Error> {
            print("Preparing wallpaper preview")
            
            printImageInfo(image: roomPhoto, title: "roomPhoto")
            printImageInfo(image: roomWallMask, title: "roomWallMask")
            printImageInfo(image: wallpaperTile, title: "wallpaperTile")
            
            // TODO: assemble preview
            
            // FIXME: for debug
            let previewImageInfo = roomPhoto.withUnsafeRgbaImageInfoPointer { roomImageInfoPtr in
                roomWallMask.withUnsafeGrayImageInfoPointer { roomWallMaskImageInfoPtr in
                    wallpaperTile.withUnsafeRgbaImageInfoPointer { wallpaperTileImageInfoPtr in
                        generate_preview(
                            roomImageInfoPtr,
                            roomWallMaskImageInfoPtr,
                            wallpaperTileImageInfoPtr,
                            roomLayout.ffiModel
                        )
                    }
                }
            }
            
            let previewImage = UIImage(fromRgbaImageInfo: previewImageInfo)
            
            switch fileHelper.savePreviewImage(image: previewImage) {
            case .success(let previewImageFile):
                print("Successfully saved preview to: \(previewImageFile.filePath)")
            case .failure(let error):
                return .failure(PreviewError(message: "Could not save preview: \(error)"))
            }
            
            return .success(previewImage)
            
        }
        
        private func printImageInfo(image: UIImage, title: String) {
            print("\n\(title)")
            let cgImage = image.cgImage!
            print("Size: \(image.size)")
            print("CG Size: \(cgImage.width)x\(cgImage.height)")
            print("Color space: \(cgImage.colorSpace!.name!), components: \(cgImage.colorSpace!.numberOfComponents)")
            print("Bits per component: \(cgImage.bitsPerComponent)")
            print("Alpha info: \(cgImage.alphaInfo)")
        }
        
        private func prepareWallpaperTile(wallpaperPhotoFile: MediaFile) async -> Result<UIImage, PreviewError> {
            let cachedWallpaperTile = fileHelper.loadWallpaperTile(id: wallpaperPhotoFile.id)
            if case .success(let wallpaperTile) = cachedWallpaperTile, wallpaperTile != nil {
                print("Loaded cached wallpaper tile")
                return .success(wallpaperTile!)
            }
            
            print("Could not load cached wallpaper tile, will perform texture synthesis")
            
            let wallpaperPhoto: UIImage
            switch fileHelper.loadWallpaperPhoto(id: wallpaperPhotoFile.id) {
            case .success(let image):
                wallpaperPhoto = image
            case .failure(let error):
                return .failure(PreviewError(message: "Could not load wallpaper photo: \(error)"))
            }
            
            let synthesisResult = await wallpaperSynthesisHelper.synthesizeWallpaperTile(fromPhoto: wallpaperPhoto)
            let wallpaperTile: UIImage
            switch synthesisResult {
            case .success(let image):
                wallpaperTile = image
            case .failure(let error):
                return .failure(PreviewError(message: "Texture synthesis failed: \(error)"))
            }
            
            // Cache synthesized wallpaper tile
            switch fileHelper.saveWallpaperTile(image: wallpaperTile, id: wallpaperPhotoFile.id) {
            case .success(let wallpaperTileFile):
                print("Successfully saved wallpaper tile to: \(wallpaperTileFile.filePath)")
            case .failure(let error):
                return .failure(PreviewError(message: "Could not save wallpaper tile: \(error)"))
            }
            
            return .success(wallpaperTile)
        }
        
        private func prepareRoomLayout(roomPhotoFile: MediaFile) async -> Result<RoomLayout, PreviewError> {
            // Check if we have cached room layout for this photo to avoid unnecessary computation
            let cachedRoomLayout = fileHelper.loadRoomLayout(id: roomPhotoFile.id)
            if case .success(let roomLayout) = cachedRoomLayout, roomLayout != nil {
                print("Loaded cached room layout")
                return .success(roomLayout!)
            }
            
            print("Could not load cached room layout, will perform new inference")
            
            let roomPhotoImage: UIImage
            switch fileHelper.loadRoomPhoto(id: roomPhotoFile.id) {
            case .success(let image):
                roomPhotoImage = image
            case .failure(let error):
                return .failure(PreviewError(message: "Could not load room photo: \(error)"))
            }
            
            let layoutObservations: [VNCoreMLFeatureValueObservation]
            let layoutInferenceResults = await inferenceHelper.extractRoomLayout(roomPhotoImage)
            switch layoutInferenceResults {
            case .success(let observations):
                if observations.count != 4 {
                    fatalError("Unexpected number of layout observations: \(observations.count) != 4")
                }
                layoutObservations = [
                    observations[0] as! VNCoreMLFeatureValueObservation,
                    observations[1] as! VNCoreMLFeatureValueObservation,
                    observations[2] as! VNCoreMLFeatureValueObservation,
                    observations[3] as! VNCoreMLFeatureValueObservation,
                ]
            case .failure(let error):
                return .failure(PreviewError(message: "Layout inference failed: \(error)"))
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
                return .failure(PreviewError(message: "Could not save room layout data: \(error)"))
            }
           
            return .success(roomLayout)
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
            
            var format = UIGraphicsImageRendererFormat()
            format.scale = 1.0
            format.opaque = true
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: segmentationMapWidth, height: segmentationMapHeight), format: format)
            
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
            print("Segmentation image size: \(image.size)")
            
            return image
        }
    }
}

extension PreviewGenerationScreen.ViewModel {
    struct PreviewError: Error {
        let message: String
    }
}
