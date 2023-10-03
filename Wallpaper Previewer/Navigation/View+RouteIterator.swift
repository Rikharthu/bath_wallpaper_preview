//
//  View+RouteIterator.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 03/10/2023.
//

import SwiftUI

extension View {
    func routeIterator() -> some View {
        self.navigationDestination(for: Route.self) { route in
            return Routes.getViewForRoute(route: route)
        }
    }
}
