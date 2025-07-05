import SwiftUI

struct ContentView: View {
    @StateObject private var booksNavigationManager = BooksNavigationManager()

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
                    .environmentObject(booksNavigationManager)
                }
                .tabItem {
                    Image(systemName: "book.closed")
                    Text("Books")
                }

                BookmarksView()
                    .tabItem {
                        Image(systemName: "bookmark")
                        Text("Bookmarks")
                    }
            }
        }
    }
}
