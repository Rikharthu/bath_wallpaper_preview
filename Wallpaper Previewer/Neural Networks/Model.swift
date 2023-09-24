//
//  Model.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 26/08/2023.
//

import Foundation
import CoreML
import Vision

// TODO: delete

// MARK: -- Room layout estimation network
func createRoomLayoutEstimationModel() -> VNCoreMLModel {
    let start = DispatchTime.now()
    
    let modelConfig = MLModelConfiguration()
    // FIXME: check if model works with .all (performance tests failed if Neural Engine was used)
    modelConfig.computeUnits = .cpuAndGPU
    let layoutNet = try! flip_combined_layoutnet_persp_mlprogram(configuration: modelConfig)
    let modelDescription = layoutNet.model.modelDescription
    
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
    print("Room type output: multi-array of shape \(typeOutputConstraint.shape) and type \(typeOutputConstraint.dataType)")
    
    let modelMetadata = modelDescription.metadata
    print("Model metadata: \(modelMetadata)")
    
    let model = try! VNCoreMLModel(for: layoutNet.model)
    
    let end = DispatchTime.now()
    let elapsedNanos = end.uptimeNanoseconds - start.uptimeNanoseconds
    let elapsedSeconds = Double(elapsedNanos) / 1_000_000_000
    print("Room layout estimation model loaded in \(elapsedSeconds) seconds")
    
    return model
}

// MARK: -- Room wall segmentation model
