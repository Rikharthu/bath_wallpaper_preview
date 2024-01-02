//
//  InstructionsView.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 04/10/2023.
//

import SwiftUI

struct InstructionsView: View {
    
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.title)
                .padding(0)
            Text(subtitle)
                .font(.subheadline)
                .padding(.bottom, 8)
            
            Divider()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

#Preview {
    InstructionsView(
        title: "Pick Room Photo",
        subtitle: "Pick or capture photo of the room you want to preview new wallpapers on."
    )
    .previewLayout(.sizeThatFits)
}
