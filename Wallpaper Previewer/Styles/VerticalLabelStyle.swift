//
//  VerticalLabelStyle().swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 14/09/2023.
//

import SwiftUI

struct VerticalLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack {
            configuration.icon
            configuration.title
        }
    }
}

extension LabelStyle where Self == VerticalLabelStyle  {
    static var verticalTitleAndIcon: VerticalLabelStyle { VerticalLabelStyle() }
}
