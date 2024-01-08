//
//  TutorialSheetView.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 04/10/2023.
//

import SwiftUI

struct TutorialSheetView: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Using the App")
                .font(.title)
            
            // TODO: include a tutorial section prior to conducting user survey and measure how many users actually accessed the tutorial section
            Text(".")
            
            Text("Constraints")
            
            Spacer()
                .frame(maxWidth: .infinity)
        }
        .padding()
    }
}

#Preview {
    TutorialSheetView()
}
