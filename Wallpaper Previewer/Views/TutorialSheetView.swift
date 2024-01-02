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
            
            
            // TODO: fill with same content as we include in the Dissertation Appendix
            Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum sagittis eleifend leo, nec ullamcorper felis iaculis vel. Phasellus sed felis erat. Maecenas sed efficitur lorem, at suscipit odio. Phasellus mauris urna, placerat quis nunc ut, feugiat vestibulum velit. Fusce a fringilla dui, sit amet eleifend sem. Quisque pharetra dapibus laoreet. Nulla facilisi. Duis diam nulla, sagittis sit amet est id, lobortis gravida diam. Aenean eu venenatis mauris. Etiam accumsan venenatis lacus aliquet tempus.")
            
            // TODO: include info on constraints (square room with floor and/or ceiling is a must)
            
            Text("Constraints")
            
            Spacer()
                .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    TutorialSheetView()
}
