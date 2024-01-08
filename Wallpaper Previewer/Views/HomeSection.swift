//
//  HomeSection.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 04/10/2023.
//

import SwiftUI

struct HomeSection: View {
    
    @StateObject
    var viewModel: HomeSectionViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(viewModel.title)
                .font(.system(size: 18, weight: .semibold))
            
            ScrollView(.horizontal) {
                ForEach(viewModel.sectionItems) { sectionItem in
                    HomeSectionItemView(
                        title: sectionItem.title,
                        subtitle: sectionItem.subtitle,
                        imageName: sectionItem.image
                    )
                    .onTapGesture {
                        viewModel.onSectionItemSelected(id: sectionItem.id)
                    }
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .sheet(isPresented: $viewModel.showingTutorialSheet) {
            TutorialSheetView()
        }
        
    }
    
    private var tutorialSectionItem: some View {
        HomeSectionItemView(
            title: "How to use the app?",
            subtitle: "Tutorial",
            imageName: "SeedData/RoomPhotos/5"
        )
    }
}

#Preview {
    HomeSection(
        viewModel: HomeSectionViewModel()
    ).previewLayout(.sizeThatFits)
}
