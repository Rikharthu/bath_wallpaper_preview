//
//  BottomTabBarView.swift
//  Wallpaper Previewer
//
//  Created by Richard Kuodis on 13/09/2023.
//

import SwiftUI

struct BottomTabBarView: View {
    
    let onPreviewButtonTapped: () -> Void
    
    @Binding
    var selectedTab: TabType
    
    var previewButton: some View {
        Circle().fill(Color(.secondarySystemBackground))
            .frame(width: 68, height: 68)
            .overlay {
                NavigationLink(value: Route.previewGeneration) {
                    PreviewButton()
                }
            }
            .offset(CGSize(width: 0, height: -16))
    }
    
    var body: some View {
        Color(.secondarySystemBackground)
            .edgesIgnoringSafeArea(.vertical)
            .frame(height: 50)
            .overlay {
                HStack {
                    Spacer()
                    TabBarItemView(
                        title: "Home",
                        icon: "house.fill",
                        selected: selectedTab == .home,
                        onTapAction: {
                            selectedTab = .home
                        }
                    )
                    Spacer()

                    previewButton

                    Spacer()

                    TabBarItemView(
                        title: "Gallery",
                        icon: "photo.fill.on.rectangle.fill",
                        selected: selectedTab == .gallery,
                        onTapAction: {
                            selectedTab = .gallery
                        }
                    )
                    Spacer()
                }
            }
    }
}

struct BottomTabBarView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            BottomTabBarView(
                onPreviewButtonTapped: {
                    print("Preview")
                },
                selectedTab: Binding.constant(.home)
            )
        }
    }
}
