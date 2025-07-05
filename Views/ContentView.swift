import SwiftUI

struct ContentView: View {

    var body: some View {
        ZStack {
            TabView {
                // Home tab
                HomeView()
                    .tabItem {
                        Image(systemName: "house")
                        Text("Home")
                    }

                // "Books" tab: the main Bible navigation/reading UI
                NavigationView {
                    NavigationStack {
                        VStack(spacing: 0) {
                            OverviewView()
                        }
                    }
                }
                .tabItem {
                    Image(systemName: "book.closed")
                    Text("Books")
                }
            }
        }
    }
}
