import SwiftUI

struct ContentView: View {
    @StateObject private var booksNavigationManager = BooksNavigationManager()
    @StateObject private var tabManager = TabSelectionManager()
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        if sizeClass == .regular {
            iPadBody
        } else {
            iPhoneBody
        }
    }

    // MARK: - Phone Layout
    private var iPhoneBody: some View {
        TabView(selection: $tabManager.selection) {
            HomeView()
                .opacity(tabManager.selection == .home ? 1 : 0)
                .animation(.easeInOut(duration: 0.3), value: tabManager.selection)
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
                .tag(AppTab.home)

            NavigationView { booksStack }
                .opacity(tabManager.selection == .books ? 1 : 0)
                .animation(.easeInOut(duration: 0.3), value: tabManager.selection)
                .tabItem {
                    Image(systemName: "book.closed")
                    Text("Books")
                }
                .tag(AppTab.books)

            StudyView()
                .opacity(tabManager.selection == .study ? 1 : 0)
                .animation(.easeInOut(duration: 0.3), value: tabManager.selection)
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

    // MARK: - iPad Layout
    private var iPadBody: some View {
        NavigationSplitView {
            List {
                sidebarRow(tab: .home)
                sidebarRow(tab: .books)
                sidebarRow(tab: .study)
            }
            .navigationTitle("VerseReminder")
            .listStyle(.sidebar)
        } detail: {
            switch tabManager.selection {
            case .home:
                HomeView()
            case .books:
                booksStack
            case .study:
                StudyView()
            }
        }
        .environmentObject(booksNavigationManager)
        .environmentObject(tabManager)
    }

    // MARK: - Sidebar Row Helper
    @ViewBuilder
    private func sidebarRow(tab: AppTab) -> some View {
        let selected = tabManager.selection == tab
        Button(action: {
            tabManager.selection = tab
        }) {
            Label(tab.title, systemImage: tab.icon)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(selected ? .accentColor : .primary)
                .background(selected ? Color.accentColor.opacity(0.12) : Color.clear)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Shared Books Navigation
    @ViewBuilder
    private var booksStack: some View {
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
    }
}

// Optional: Helper for sidebar titles/icons if needed
extension AppTab {
    var title: String {
        switch self {
        case .home: return "Home"
        case .books: return "Books"
        case .study: return "Study"
        }
    }
    var icon: String {
        switch self {
        case .home: return "house"
        case .books: return "book.closed"
        case .study: return "books.vertical"
        }
    }
}
