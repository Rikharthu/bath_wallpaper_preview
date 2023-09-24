//
//  RoomInferenceHelper.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 18/09/2023.
//

import CoreML
import SwiftUI
import Vision

final class RoomInferenceHelper {
    
    func extractRoomLayout(_ image: UIImage) async -> Result<[VNObservation], Error> {
        let fixedImage = image.fixOrientation()
        
        let sourceImageOrientation = image.imageOrientation
        let sourceImageScale = image.scale
        print("Image orientation: \(sourceImageOrientation), scale: \(sourceImageScale)")
        
        let layoutModel = await loadLayoutModel()
        
        let observationResults = await withCheckedContinuation { (continuation: CheckedContinuation<Result<[VNObservation], Error>, Never>) in
            let segmentationRequest = VNCoreMLRequest(model: layoutModel) { request, error in
                if let error {
                    continuation.resume(returning: .failure(error))
                } else {
                    continuation.resume(returning: .success(request.results!))
                }
            }
            segmentationRequest.imageCropAndScaleOption = .centerCrop
            
            let cgImageOrientation = CGImagePropertyOrientation(sourceImageOrientation)
            print("Input image orientation: \(cgImageOrientation), is up: \(cgImageOrientation == .up)")
            
            let handler = VNImageRequestHandler(
                cgImage: image.cgImage!,
                orientation: .up,
                options: [:]
            )
            
            do {
                try handler.perform([segmentationRequest])
            } catch {
                continuation.resume(returning: .failure(error))
            }
        }
        
        return observationResults
    }
    
    func segmentImage(_ image: UIImage) async -> Result<VNObservation, Error> {
        let fixedImage = image.fixOrientation()
        
        let sourceImageOrientation = image.imageOrientation
        let sourceImageScale = image.scale
        print("Image orientation: \(sourceImageOrientation), scale: \(sourceImageScale)")
        
        // TODO: consider caching it if we ever need to reuse it
        let segmentationModel = await loadSegmentationModel()
        
        let observationResult = await withCheckedContinuation { (continuation: CheckedContinuation<Result<VNObservation, Error>, Never>) in
            let segmentationRequest = VNCoreMLRequest(model: segmentationModel) { request, error in
                if let error {
                    continuation.resume(returning: .failure(error))
                } else {
                    let observation: VNObservation = request.results!.first!
                    continuation.resume(returning: .success(request.results!.first!))
                }
            }
            segmentationRequest.imageCropAndScaleOption = .centerCrop
            
            let cgImageOrientation = CGImagePropertyOrientation(sourceImageOrientation)
            print("Input image orientation: \(cgImageOrientation), is up: \(cgImageOrientation == .up)")
            
            let handler = VNImageRequestHandler(
                cgImage: image.cgImage!,
                orientation: .up,
                options: [:]
            )
            
            do {
                try handler.perform([segmentationRequest])
            } catch {
                continuation.resume(returning: .failure(error))
            }
        }
        
        return observationResult
    }
    
    private func loadLayoutModel() async -> VNCoreMLModel {
        let modelConfig = MLModelConfiguration()
        modelConfig.computeUnits = .cpuAndGPU // FIXME: For some reason model often crashes on neural units during preview
        
        let layoutModel = try! flip_combined_layoutnet_persp_mlprogram(configuration: modelConfig)
        let modelDescription = layoutModel.model.modelDescription
        
        // MARK: Input
        let input = modelDescription.inputDescriptionsByName["input"]!
        let inputConstraint = input.imageConstraint!
        print("Input: image of size \(inputConstraint.pixelsWide)x\(inputConstraint.pixelsHigh) and type \(inputConstraint.pixelFormatType)")
        // pixelFormatType of 1111970369 translated from ASCII is BGRA
        // https://ubershmekel.github.io/fourcc-to-text/
        
        // MARK: Outputs
        let edgesOutput = modelDescription.outputDescriptionsByName["edges"]!
        let edgesOutputConstraint = edgesOutput.multiArrayConstraint!
        print("Edges output: multi-array of shape \(edgesOutputConstraint.shape) and type \(edgesOutputConstraint.dataType)")
        
        let cornersOutput = modelDescription.outputDescriptionsByName["corners"]!
        let cornersOutputConstraint = cornersOutput.multiArrayConstraint!
        print("Corners output: multi-array of shape \(cornersOutputConstraint.shape) and type \(cornersOutputConstraint.dataType)")
        
        let cornersFlipOutput = modelDescription.outputDescriptionsByName["corners_flip"]!
        let cornersFlipOutputConstraint = cornersFlipOutput.multiArrayConstraint!
        print("Flipped corners output: multi-array of shape \(cornersFlipOutputConstraint.shape) and type \(cornersFlipOutputConstraint.dataType)")
        
        let typeOutput = modelDescription.outputDescriptionsByName["type"]!
        let typeOutputConstraint = typeOutput.multiArrayConstraint!
        print("Room type output: multi-array of shape \(typeOutputConstraint.shape) - \(typeOutputConstraint.shapeConstraint.enumeratedShapes) and type \(typeOutputConstraint.dataType)")
        
        let modelMetadata = modelDescription.metadata
        print("Model metadata: \(modelMetadata)")
        
        let model = try! VNCoreMLModel(for: layoutModel.model)
        return model
    }
    
    private func loadSegmentationModel() async -> VNCoreMLModel {
        let modelConfig = MLModelConfiguration()
        modelConfig.computeUnits = .all
        
        let segmentationModel = try! DeepLabV3Plus_mobileone_s3(configuration: modelConfig)
        let modelDescription = segmentationModel.model.modelDescription
        
        let modelInput = modelDescription.inputDescriptionsByName["input"]!
        let inputConstraint = modelInput.imageConstraint!
        print("Input: images of size \(inputConstraint.pixelsWide)x\(inputConstraint.pixelsHigh) and type \(inputConstraint.pixelFormatType)")
        // pixelFormatType of 1111970369 translated from ASCII is BGRA
        // https://ubershmekel.github.io/fourcc-to-text/
        
        let modelOutput = modelDescription.outputDescriptionsByName["output"]!
        let outputConstraint = modelOutput.multiArrayConstraint!
        print("Output: multi-array of shape \(outputConstraint.shape) and type \(outputConstraint.dataType)")
        
        let modelMetadata = modelDescription.metadata
        print("Model metadata: \(modelMetadata)")
        
        return try! VNCoreMLModel(for: segmentationModel.model)
    }
}
