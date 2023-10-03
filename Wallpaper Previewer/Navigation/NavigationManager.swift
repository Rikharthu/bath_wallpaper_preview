//
//  NavigationManager.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 03/10/2023.
//

import SwiftUI

// Implementation modified from:
//   https://medium.com/@mhmtkrnlk/programmatic-navigation-with-new-navigationstack-38dca684897f
class NavigationManager: ObservableObject {
    
    @Published
    var routes: [Route] = []
    
    func popToRoot() {
        self.routes.removeAll()
    }
    
    func pop() {
        self.routes.removeLast()
    }
    
    func popUntil(_ targetRoute: Route){
        if self.routes.isEmpty {
            return
        }
        if self.routes.last != targetRoute {
            self.routes.removeLast()
            popUntil(targetRoute)
        }
    }
}
