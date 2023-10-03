import CoreML
import SwiftUI
// import Vision

struct ContentView: View {
    
    @State private var selectedTab: TabType = .home

    var body: some View {
        Navigator { navigationManager in
            VStack(spacing: 0) {
                TabView(selection: $selectedTab) {
                    Text("Home")
                        .tag(TabType.home)
                    GalleryScreen()
                        .tag(TabType.gallery)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                BottomTabBarView(
                    onPreviewButtonTapped: {},
                    selectedTab: $selectedTab
                )
            }
            .routeIterator()
        }
        .task {
#if DEBUG
            await seedInitialDataIfNeeded()
#endif
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
