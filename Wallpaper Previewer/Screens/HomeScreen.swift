//
//  HomeScreen.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 04/10/2023.
//

import SwiftUI

struct HomeScreen: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Home")
                .font(.largeTitle)
                .padding(.top, 16)
                .padding(.horizontal, 16)
            
            HomeSection(
                viewModel: HomeSectionViewModel()
            )
            Spacer()
        }
    }
}

#Preview {
    HomeScreen()
}
