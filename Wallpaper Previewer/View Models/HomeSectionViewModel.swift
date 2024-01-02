//
//  HomeSectionViewModel.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 04/10/2023.
//

import SwiftUI

@MainActor
class HomeSectionViewModel: ObservableObject {
    
    // TODO: switch to enums
    private static let getStartedId = 0
    
    @Published
    var title: String = "Get Started"
    
    @Published
    var showingTutorialSheet: Bool = false
    
    // TODO: add more section items like in Planta and Coin apps that will navigate to app functionality, such as "Show my previews", "Create new preview", "Scan a wallpaper"
    // TODO: add an option item to download more patterns from the internet
    @Published
    var sectionItems = [
        HomeSectionItem(
            id: getStartedId,
            title: "How to use the app?",
            subtitle: "Tutorial",
            image: "SeedData/RoomPhotos/5"
        )
    ]
    
    func onSectionItemSelected(id: Int) {
        switch id {
        case Self.getStartedId:
            onGetStartedSectionItemSelected()
        default:
            print("Unknown section item with id \(id) selected")
            break
        }
    }
    
    private func onGetStartedSectionItemSelected() {
        showingTutorialSheet = true
    }
}
