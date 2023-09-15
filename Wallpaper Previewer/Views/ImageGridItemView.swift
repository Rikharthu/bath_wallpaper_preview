//
//  ImageGridItemView.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 14/09/2023.
//

import SwiftUI

struct ImageGridItemView: View {
    let imageFilePath: String

    var body: some View {
        Image(
            uiImage: UIImage(contentsOfFile: imageFilePath)
                ?? UIImage(systemName: "photo")!
        )
        .resizable()
        .aspectRatio(1, contentMode: .fill)
        .cornerRadius(12)
    }
}

struct ImageGridItemView_Previews: PreviewProvider {
    static var previews: some View {
        ImageGridItemView(
            imageFilePath: "some/random/path"
        ).previewLayout(.sizeThatFits)
    }
}
