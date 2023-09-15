//
//  HeaderView.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 13/09/2023.
//

import SwiftUI

struct GalleryHeaderView: View {
    let mainTitle: String
    let topTitle: String
    @Binding var selectedTab: GalleryType

    var body: some View {
        VStack(alignment: .leading) {
            Text(topTitle)
            
            Text(mainTitle)
                .font(.headline)
                .fontWeight(.bold)

                Picker("Title", selection: $selectedTab) {
                    Text("Rooms").tag(GalleryType.rooms)
                    Text("Wallpapers").tag(GalleryType.wallpapers)
                    Text("Previews").tag(GalleryType.previews)
                }
                .onChange(of: selectedTab, perform: { newValue in
                    let impactLight = UIImpactFeedbackGenerator(style: .light)
                    impactLight.impactOccurred()
                })
                .pickerStyle(SegmentedPickerStyle())
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
    }
}

struct GalleryHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        GalleryHeaderView(
            mainTitle: "My Gallery",
            topTitle: "4 Rooms",
            selectedTab: Binding.constant(.rooms)
        )
        .previewLayout(.sizeThatFits)
    }
}
