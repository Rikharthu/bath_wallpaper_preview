//
//  TabBarItemView.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 13/09/2023.
//

import SwiftUI

struct TabBarItemView: View {
    
    // TODO: on tap handler
    
    let title: String
    let icon: String
    let selected: Bool
    let onTapAction: () -> Void
    
    var body: some View {
        Label(
            title,
            systemImage: icon
        ).labelStyle(.verticalTitleAndIcon)
            .onTapGesture {
                onTapAction()
            }
            // Can't click on an already selected item
            .disabled(selected)
            .foregroundColor(selected ? Color.blue : Color.gray)
    }
}

struct TabBarItemView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarItemView(
            title: "Home",
            icon: "house.fill",
            selected: true,
            onTapAction: {
                print("Tap")
            }
        ).previewLayout(.sizeThatFits)
            .previewDisplayName("Selected")
        
        TabBarItemView(
            title: "Gallery",
            icon: "house.fill",
            selected: false,
            onTapAction: {
                print("Tap")
            }
        ).previewLayout(.sizeThatFits)
        .previewDisplayName("Deselected")
    }
}
