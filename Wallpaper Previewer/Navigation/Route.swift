//
//  Route.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 18/09/2023.
//

import SwiftUI

enum Route: Hashable, CaseIterable {
    case previewGeneration
}

enum Routes {
    static let routes: [Route: AnyView] = [
        .previewGeneration: AnyView(PreviewGenerationScreen())
    ]
    
    static func getViewForRoute(route: Route) -> some View {
        let index = Self.routes.index(forKey: route)!
        return Self.routes[index].value
    }
}
