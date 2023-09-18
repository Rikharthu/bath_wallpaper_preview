//
//  PreviewButton.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 13/09/2023.
//

import SwiftUI

struct PreviewButton: View {
    
    var body: some View {
        ZStack(alignment: .center) {
            Circle()
                .fill(Color("LightBlue"))
                .frame(width: 56, height: 56)
            Circle()
                .fill(Color("Blue"))
                .frame(width: 48, height: 48)
            
            Image(systemName: "paintbrush.fill")
                .foregroundColor(.white)
                .font(.system(size: 28))
        }
    }
}

struct PhotoButton_Previews: PreviewProvider {
    static var previews: some View {
        PreviewButton()
            .previewLayout(.sizeThatFits)
    }
}
