import SwiftUI

struct ContentView: View {

    var body: some View {
        ZStack {
            TabView {
                // "Books" tab: the main Bible navigation/reading UI
                NavigationView {
                    VStack(spacing: 0) {
                        OverviewView()
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
