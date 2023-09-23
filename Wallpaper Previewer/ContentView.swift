import CoreML
import SwiftUI
// import Vision

struct ContentView: View {
//    @StateObject private var viewModel = ContentViewModel()
//    @State private var image = UIImage()
//    @State private var image2 = UIImage()
//    @State private var showSheet = false
//    @State private var segmentationObservation: VNObservation? = nil
//    private let mlProcessingQueue = DispatchQueue(label: "ml_processing")
    
    // TODO: To make loading faster, load it in background during initialization (e.g. ViewModel.init call with progress bar)
//    private let roomLayoutModel = createRoomLayoutEstimationModel()
    
    @State private var selectedTab: TabType = .home

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TabView(selection: $selectedTab) {
                    Color(.red)
                        .overlay(Text("Home"))
                        .tag(TabType.home)
                    GalleryScreen()
                        .tag(TabType.gallery)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                BottomTabBarView(
                    onPreviewButtonTapped: {},
                    selectedTab: $selectedTab
                )
            }
            
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .previewGeneration:
                    PreviewGenerationScreen()
                }
            }
        }
        .task {
            // TODO: check if we are in a debug configuration, and seed initial data if not already
            #if DEBUG
                await seedInitialDataIfNeeded()
            #endif
        }
        
//        VStack {
//            HStack {
//                Image(uiImage: self.image)
//                    .resizable()
//                    .frame(width: 100, height: 100)
//                    .background(Color.black.opacity(0.2))
//                    .aspectRatio(contentMode: .fill)
//
//                Image(uiImage: self.image2)
//                    .resizable()
//                    .frame(width: 100, height: 100)
//                    .background(Color.black.opacity(0.2))
//                    .aspectRatio(contentMode: .fill)
//
//                Text("Change photo")
//                    .font(.headline)
//                    .frame(maxWidth: .infinity)
//                    .frame(height: 50)
//                    .background(LinearGradient(gradient: Gradient(colors: [Color(#colorLiteral(red: 0.262745098, green: 0.0862745098, blue: 0.8588235294, alpha: 1)), Color(#colorLiteral(red: 0.5647058824, green: 0.462745098, blue: 0.9058823529, alpha: 1))]), startPoint: .top, endPoint: .bottom))
//                    .cornerRadius(16)
//                    .foregroundColor(.white)
//                    .padding(.horizontal, 20)
//                    .onTapGesture {
//                        let sum = shipping_rust_addition(3, 4)
//                        print("Sum: \(sum)")
//                        showSheet = true
//                    }
//
//                Button("Do something") {
//                    doSomething()
//                }
//            }
//
//            Group {
//                if let observation = self.segmentationObservation {
//                    SegmentationVisualizationView(observation: observation)
//                } else {
//                    Text("Empty")
//                }
//            }
//            .frame(width: 256, height: 256)
//        }
//        .padding(.horizontal, 20)
//        .sheet(isPresented: $showSheet) {
//            // Pick an image from the photo library:
//            // ImagePicker(sourceType: .photoLibrary, selectedImage: self.$image)
//
//            //  If you wish to take a photo from camera instead:
//             ImagePicker(sourceType: .camera, selectedImage: self.$image)
//        }
//        .task {
//            self.image = UIImage(named: "room_2")!
//        }
//        .onChange(of: image) { image in
//            // self.onImageChanged(image)
//
//            let fixedImage = image.fixOrientation()
//            self.segmentImage(fixedImage)
//
//            // TODO: is it SwiftUI-way of doing things?
//            Task(priority: .userInitiated) {
//                await viewModel.processRoomImage(fixedImage)
//            }
//        }
    }

//    func doSomething() {
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
//        process_segmentation_map(&segmentationMap)
//    }
//
//    func segmentImage(_ image: UIImage) {
//        let sourceImageOrientation = image.imageOrientation
//        let sourceImageScale = image.scale
//        print("Image orientation: \(sourceImageOrientation)")
//        print("Image scale: \(sourceImageScale)")
//
    ////        let segmentationModel = try! VNCoreMLModel(
    ////            for: SegmentationModel_with_metadata(configuration: modelConfiguration).model
    ////        )
//
//
//        let segmentationModel = {
//            let modelConfig = MLModelConfiguration()
//            modelConfig.computeUnits = .all
//            // let segmentationModel = try! SegmentationModelArgmax(configuration: modelConfig)
//
//            let segmentationModel = try! DeepLabV3Plus_mobileone_s3(configuration: modelConfig)
//
//            let modelDescription = segmentationModel.model.modelDescription
//
//            let modelInput = modelDescription.inputDescriptionsByName["input"]!
//            let inputConstraint = modelInput.imageConstraint!
//            print("Input: images of size \(inputConstraint.pixelsWide)x\(inputConstraint.pixelsHigh) and type \(inputConstraint.pixelFormatType)")
//            // pixelFormatType of 1111970369 translated from ASCII is BGRA
//            // https://ubershmekel.github.io/fourcc-to-text/
//
//            let modelOutput = modelDescription.outputDescriptionsByName["output"]!
//            let outputConstraint = modelOutput.multiArrayConstraint!
//            print("Output: multi-array of shape \(outputConstraint.shape) and type \(outputConstraint.dataType)")
//            print("\(modelOutput)")
//
//            let modelMetadata = modelDescription.metadata
//            print("Model metadata: \(modelMetadata)")
//
//            return try! VNCoreMLModel(for: segmentationModel.model)
//        }()
//
//        let segmentationRequest = VNCoreMLRequest(model: segmentationModel) { request, error in
//            // self.observationResults = request.results as? [VNObservation]
//            // self.isProcessing = false
//
//            if let error {
//                print("Error performing segmentation: \(error)")
//                return
//            }
//
//            DispatchQueue.main.async {
//                let result: VNObservation? = request.results?.first!
//                self.segmentationObservation = result
//            }
//        }
//        segmentationRequest.imageCropAndScaleOption = .centerCrop
//
//        let cgImageOrientation = CGImagePropertyOrientation(sourceImageOrientation)
//        print("Input image orientation: \(cgImageOrientation), is up: \(cgImageOrientation == .up)")
//        mlProcessingQueue.async {
//            let handler = VNImageRequestHandler(
//                cgImage: image.cgImage!,
//                orientation: cgImageOrientation,
//                options: [:]
//            )
//
//            // TODO: research whether there are better performance if we submit multiple requests at the same time
//            //   rather than individually
//            try! handler.perform([segmentationRequest])
//        }
//    }
//
//    func onImageChanged(_ image: UIImage) {
//        // TODO: to get raw bytes, condiser using this helper: https://github.com/hollance/CoreMLHelpers/blob/master/CoreMLHelpers/CGImage%2BRawBytes.swift
//
//        let rgbData = image.pixelValuesRgba()
//        print("RGB count: \(rgbData?.count)")
//        print("First elements \(rgbData?[0...21])")
//
//        if let rgbData = rgbData {
//            let processedRgbData = rgbData.withUnsafeBufferPointer { ptr in
//                let image_info = RgbaImageInfo(
//                    data: ptr.baseAddress!,
//                    count: UInt(rgbData.count),
//                    width: UInt(image.size.width),
//                    height: UInt(image.size.height)
//                )
//                return withUnsafePointer(to: image_info) { image_info in
//                    rust_process_data(image_info)!
//                }
//            }
//
//            // TODO: does any of methods below take ownership of buffer? If so, it must be copied as this memory belongs to Rust and must be freed.
//            let buffer = UnsafeBufferPointer(start: processedRgbData, count: rgbData.count)
//            var array = Array(buffer)
//            print("Returned first elements \(array[0...21])")
//
//            let reconstrucedCGImage = array.withUnsafeMutableBytes { ptr -> CGImage in
//                let context = CGContext(
//                    data: ptr.baseAddress,
//                    width: Int(image.size.width),
//                    height: Int(image.size.height),
//                    bitsPerComponent: 8,
//                    bytesPerRow: 4 * Int(image.size.width),
//                    space: CGColorSpace(name: CGColorSpace.sRGB)!,
//                    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
//                )!
//                return context.makeImage()!
//            }
//            let reconstructedImage = UIImage(cgImage: reconstrucedCGImage)
//            image2 = reconstructedImage
//            // TODO: processedRgbData must be freed in Rust
//
//            // TODO: for now hardcoded to 256x256 RGBA image
//            let synthesizedRgbaDataCount = 256 * 256 * 4
//            let synthesizedRgbaData = rgbData.withUnsafeBufferPointer { ptr in
//                let image_info = RgbaImageInfo(
//                    data: ptr.baseAddress!,
//                    count: UInt(rgbData.count),
//                    width: UInt(image.size.width),
//                    height: UInt(image.size.height)
//                )
//                return withUnsafePointer(to: image_info) { image_info in
//                    // TODO: pass generator process callback to report progress on UI
//                    //   https://github.com/thombles/dw2019rust/blob/master/modules/07%20-%20Swift%20callbacks.md
//                    //   Also describe this in Disseration, as it is basic of UX - report progress for long-running tasks
//                    synthesize_texture(image_info)!
//                }
//            }
//
//            // TODO: does any of methods below take ownership of buffer? If so, it must be copied as this memory belongs to Rust and must be freed.
//            let buffer2 = UnsafeBufferPointer(start: synthesizedRgbaData, count: synthesizedRgbaDataCount)
//            var array2 = Array(buffer2)
//            print("Returned first elements \(array2[0...21])")
//
//            let synthesizedCGImage = array2.withUnsafeMutableBytes { ptr -> CGImage in
//                let context = CGContext(
//                    data: ptr.baseAddress,
//                    width: 256,
//                    height: 256,
//                    bitsPerComponent: 8,
//                    bytesPerRow: 4 * 256,
//                    space: CGColorSpace(name: CGColorSpace.sRGB)!,
//                    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
//                )!
//                return context.makeImage()!
//            }
//            let synthesizedImage = UIImage(cgImage: synthesizedCGImage)
//            image2 = synthesizedImage
//        }
//    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
