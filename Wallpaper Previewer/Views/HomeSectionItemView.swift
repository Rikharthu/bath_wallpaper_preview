//
//  HomeSectionItemView.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 04/10/2023.
//

import SwiftUI

struct HomeSectionItemView: View {
    
    let title: String
    let subtitle: String
    let imageName: String
    
    var body: some View {
        ZStack(alignment: .top) {
            Image(uiImage: UIImage(named: imageName)!)
                .resizable()
                .scaledToFill()
                .clipped()
                .frame(width: 200, height: 160)
            
            VStack(spacing: 0) {
                Spacer()
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background {
                    Color.black.opacity(0.6)
                }
            }
        }
        .frame(width: 200, height: 160)
        .cornerRadius(12)
    }
}

#Preview {
    HomeSectionItemView(
        title: "How to use the app?",
        subtitle: "Tutorial",
        imageName: "SeedData/RoomPhotos/5"
    )
}
