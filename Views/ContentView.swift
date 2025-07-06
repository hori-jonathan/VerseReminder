import SwiftUI

struct ContentView: View {
    @StateObject private var booksNavigationManager = BooksNavigationManager()
    @StateObject private var tabManager = TabSelectionManager()
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        ZStack {
            TabView(selection: $tabManager.selection) {
                // Home tab
                HomeView()
                    .tabItem {
                        Image(systemName: "house")
                        Text("Home")
                    }
                    .tag(AppTab.home)

                // "Books" tab: the main Bible navigation/reading UI
                NavigationView {
                    NavigationStack(path: $booksNavigationManager.path) {
                        VStack(spacing: 0) {
                            OverviewView()
                        }
                        .navigationDestination(for: BooksRoute.self) { route in
                            switch route {
                            case .expandedBook(let id):
                                if let book = (oldTestamentCategories + newTestamentCategories)
                                    .flatMap({ $0.books })
                                    .first(where: { $0.id == id }) {
                                    ExpandedBookView(
                                        book: book,
                                        searchManager: BibleSearchManager(),
                                        chaptersRead: authViewModel.profile.chaptersRead.mapValues { Set($0) },
                                        chaptersBookmarked: authViewModel.profile.chaptersBookmarked.mapValues { Set($0) },
                                        lastRead: authViewModel.profile.lastRead.reduce(into: [String: (chapter: Int, verse: Int)]()) { partial, item in
                                            partial[item.key] = (item.value["chapter"] ?? 1, item.value["verse"] ?? 0)
                                        }
                                    ) { b, chapter in
                                        booksNavigationManager.path.append(
                                            BooksRoute.chapter(bookId: b.id, chapter: chapter, highlight: nil))
                                    }
                                }
                            case .chapter(let bid, let chap, let highlight):
                                ChapterView(
                                    chapterId: "\(bid).\(chap)",
                                    bibleId: authViewModel.profile.bibleId,
                                    highlightVerse: highlight
                                )
                            }
                        }
                    }
                    .environmentObject(booksNavigationManager)
                }
                .tabItem {
                    Image(systemName: "book.closed")
                    Text("Books")
                }
                .tag(AppTab.books)

                StudyView()
                    .environmentObject(booksNavigationManager)
                    .tabItem {
                        Image(systemName: "books.vertical")
                        Text("Study")
                    }
                    .tag(AppTab.study)
            }
            .environmentObject(booksNavigationManager)
            .environmentObject(tabManager)
        }
    }
}
