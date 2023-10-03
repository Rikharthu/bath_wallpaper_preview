//
//  Navigator.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 03/10/2023.
//

import SwiftUI

struct Navigator<Content: View>: View {
    let content: (NavigationManager) -> Content
    
    @StateObject
    var manager = NavigationManager()
    
    var body: some View {
        NavigationStack(path: $manager.routes) {
            content(manager)
        }
        .environmentObject(manager)
    }
}
