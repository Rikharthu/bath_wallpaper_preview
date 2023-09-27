//
//  ImageGridItemView.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 14/09/2023.
//

import SwiftUI

struct ImageGridItemView: View {
    let imageFilePath: String
    @State
    private var image: UIImage?

    var imageView: Image {
        if let image = image {
            Image(uiImage: image)
        } else {
            Image(systemName: "photo")
        }
    }

    var body: some View {
        // TODO: use AsyncImage
        imageView
            .resizable()
            .renderingMode(.original)
            .aspectRatio(1, contentMode: .fill)
            .cornerRadius(12)
            .foregroundColor(.gray)
            .task {
                image = UIImage(contentsOfFile: imageFilePath)
            }
    }
}

struct ImageGridItemView_Previews: PreviewProvider {
    static var previews: some View {
        ImageGridItemView(
            imageFilePath: "some/random/path"
        ).previewLayout(.sizeThatFits)
    }
}
