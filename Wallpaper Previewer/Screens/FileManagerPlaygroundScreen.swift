//
//  FileManagerPlaygroundView.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 04/09/2023.
//

import SwiftUI

struct FileManagerPlaygroundScreen: View {
    
    private let mediaDirectory = try! FileManager.default.url(
        for: .documentDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: false
    ).appendingPathComponent("Media", isDirectory: true)
    private let fileHelper = try! FileHelper.create().get()
    
    @State
    var pictureFiles = [MediaFile]()
    
    var body: some View {
        VStack(alignment: .leading) {
            
            List {
                ForEach(pictureFiles, id: \.self.id) { mediaFile in
                    HStack {
                        Text(mediaFile.id)
                        Spacer()
                        Image(uiImage: UIImage(contentsOfFile: mediaFile.filePath)!)
                            .resizable()
                            .frame(width: 32, height: 32)
                    }
                    .onTapGesture {
                        onImageSelected(id: mediaFile.id)
                    }
                }
            }
            
            Spacer()
            Button("Do something") {
                let image = UIImage(named: "lenna")!
                let id = try! fileHelper.saveRoomPhoto(image: image).get()
                print("Saved room photo with id: \(id))")
                
//                let temporaryFolderURL = URL(fileURLWithPath: NSTemporaryDirectory())
//
//                let image = UIImage(named: "lenna")!
//                let timestamp = NSDate().timeIntervalSince1970
//                let imageFileName = "\(timestamp).jpg"
//
//                // TODO: use custom sub-directory for app data
//                //   let nestedFolderURL = rootFolderURL.appendingPathComponent("MyAppFiles")
//
//                let imageFileUrl = mediaDirectory.appendingPathComponent(imageFileName)
//
//                let imageData = image.jpegData(compressionQuality: 1.0)!
//                try! imageData.write(to: imageFileUrl)
//
//                print("Saving image to: \(imageFileUrl)")
                
                refreshPicturesList()
            }
            .padding(.bottom, 12)
        }
        .onAppear{
            refreshPicturesList()
        }
    }
    
    private func onImageSelected(id: String) {
        // TODO
    }
    
    private func refreshPicturesList() {
        pictureFiles = try! fileHelper.getRoomPhotos().get()
        
//        let exists = FileManager.default.fileExists(atPath: mediaDirectory.path)
//        print("Photos directory exists: \(exists)")
//        if !exists {
//            try! FileManager.default.createDirectory(
//                at: mediaDirectory,
//                withIntermediateDirectories: true
//            )
//        }
//
//
//
//        let picturesDirectoryContents = try! FileManager.default.contentsOfDirectory(
//            at: mediaDirectory,
//            includingPropertiesForKeys: nil
//        )
//
//        pictureFiles = picturesDirectoryContents.map { $0.lastPathComponent }
    }
}

struct FileManagerPlaygroundView_Previews: PreviewProvider {
    static var previews: some View {
        FileManagerPlaygroundScreen()
    }
}
