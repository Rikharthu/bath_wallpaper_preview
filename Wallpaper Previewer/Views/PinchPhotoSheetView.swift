//
//  PinchPhotoSheetView.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 15/09/2023.
//

import SwiftUI

struct PinchPhotoSheetView: View {
    let photoFilePath: String
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Color(.white)
                .frame(height: 48)
                .frame(maxWidth: .infinity)
                .overlay {
                    Capsule()
                        .fill(Color.secondary)
                        .frame(width: 35, height: 3)
                }
                .zIndex(1)
            Divider()
            
            PinchPhotoView(photoFilePath: photoFilePath)
                .background(Color("BackgroundGray"))
        }
    }
}

struct PinchPhotoSheetView_Previews: PreviewProvider {
    static var previews: some View {
        Color(.red)
            .sheet(isPresented: Binding.constant(true)) {
                PinchPhotoSheetView(photoFilePath: "/path/to/some/image")
            }
    }
}
