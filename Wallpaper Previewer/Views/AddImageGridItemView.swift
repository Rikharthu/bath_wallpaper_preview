//
//  AddImageGridItemView.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 14/09/2023.
//

import SwiftUI

struct AddImageGridItemView: View {
    let onTapAction: () -> Void

    var body: some View {
        Image(systemName: "plus.app")
            .resizable()
            .fontWeight(.thin)
            .foregroundColor(.blue)
            .aspectRatio(1, contentMode: .fit)
            .padding(12)
            .cornerRadius(12)
            .onTapGesture {
                onTapAction()
            }
    }
}

struct AddImageGridItemView_Previews: PreviewProvider {
    static var previews: some View {
        AddImageGridItemView {
            print("Tapped!")
        }
        .previewLayout(.fixed(width: 120, height: 120))
    }
}
