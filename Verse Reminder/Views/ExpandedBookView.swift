import SwiftUI

struct ExpandedBookView: View {
    var book: BibleBook
    @ObservedObject var searchManager: BibleSearchManager
    let chaptersRead: [String: Set<Int>]
    let chaptersBookmarked: [String: Set<Int>]
    let lastRead: [String: (chapter: Int, verse: Int)]
    let onSelectChapter: (BibleBook, Int) -> Void

    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var booksNav: BooksNavigationManager
    @EnvironmentObject var tabManager: TabSelectionManager
    @Environment(\.dismiss) private var dismiss

    @State private var showBookmarks = false

    var body: some View {
        VStack(spacing: 0) {
            SearchBar(searchManager: searchManager, placeholder: "Search \(book.name) (e.g., 3 or 3:16)")
            if searchManager.showingSearchResults {
                SearchResultsView(searchManager: searchManager) { result in
                    handleSearchResult(result)
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 16) {
                        ForEach(1...book.chapters, id: \.self) { chapter in
                            Button(action: { onSelectChapter(book, chapter) }) {
                                ZStack {
                                    Text("\(chapter)")
                                        .font(.footnote)
                                        .frame(width: 36, height: 36)
                                        .background(
                                            (chaptersRead[book.id]?.contains(chapter) ?? false)
                                                ? Color.blue.opacity(0.85)
                                                : Color.red.opacity(0.13)
                                        )
                                        .foregroundColor((chaptersRead[book.id]?.contains(chapter) ?? false) ? .white : .primary)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(
                                                    (chaptersRead[book.id]?.contains(chapter) ?? false) ? Color.blue : Color.red,
                                                    lineWidth: 1.2
                                                )
                                        )
                                    if (chaptersBookmarked[book.id]?.contains(chapter) ?? false) {
                                        Image(systemName: "star.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 11, height: 11)
                                            .foregroundColor(.yellow)
                                            .offset(x: 9, y: -9)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
            }

        }
        .onAppear {
            searchManager.scopeBook = book
            searchManager.bibleId = authViewModel.profile.bibleId
        }
        .onChange(of: authViewModel.profile.bibleId) { newId in
            searchManager.bibleId = newId
        }
        .onDisappear {
            searchManager.scopeBook = nil
            searchManager.clearSearch()
        }
        .navigationTitle(book.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack {
                        Image(systemName: "chevron.backward")
                        Text("Back")
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button(action: { showBookmarks = true }) {
                        Image(systemName: "bookmark")
                    }
                    Button(action: backToBooks) {
                        Image(systemName: "book.closed")
                    }
                }
            }
        }
        .sheet(isPresented: $showBookmarks) {
            BookmarksView()
                .environmentObject(booksNav)
        }
    }

    private func handleSearchResult(_ result: BibleSearchResult) {
        switch result.type {
        case .book:
            booksNav.path.append(BooksRoute.expandedBook(result.book.id))
            searchManager.clearSearch()
        case .chapter:
            onSelectChapter(result.book, result.chapter ?? 1)
            searchManager.clearSearch()
        case .verse:
            booksNav.path.append(
                BooksRoute.chapter(bookId: result.book.id,
                                   chapter: result.chapter ?? 1,
                                   highlight: result.verse)
            )
            searchManager.clearSearch()
        }
    }

    private func backToBooks() {
        booksNav.popToRoot(tabManager: tabManager)
    }
}

