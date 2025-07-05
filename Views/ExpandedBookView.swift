import SwiftUI

struct ExpandedBookView: View {
    var book: BibleBook
    @ObservedObject var searchManager: BibleSearchManager
    let chaptersRead: [String: Set<Int>]
    let chaptersBookmarked: [String: Set<Int>]
    let lastRead: [String: (chapter: Int, verse: Int)]
    let onSelectChapter: (BibleBook, Int) -> Void

    @EnvironmentObject var booksNav: BooksNavigationManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedChapter: (book: BibleBook, chapter: Int, verse: Int?)? = nil
    @State private var selectedBook: BibleBook? = nil
    @State private var hasReceivedTrigger = false

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

            NavigationLink(
                destination: selectedChapter.map {
                    ChapterView(
                        chapterId: "\($0.book.id).\($0.chapter)",
                        bibleId: defaultBibleId,
                        highlightVerse: $0.verse
                    )
                },
                isActive: Binding(
                    get: { selectedChapter != nil },
                    set: { if !$0 { selectedChapter = nil } }
                )
            ) { EmptyView() }

            NavigationLink(
                destination: selectedBook.map {
                    ExpandedBookView(
                        book: $0,
                        searchManager: searchManager,
                        chaptersRead: chaptersRead,
                        chaptersBookmarked: chaptersBookmarked,
                        lastRead: lastRead,
                        onSelectChapter: onSelectChapter
                    )
                },
                isActive: Binding(
                    get: { selectedBook != nil },
                    set: { if !$0 { selectedBook = nil } }
                )
            ) { EmptyView() }
        }
        .onAppear { searchManager.scopeBook = book }
        .onReceive(booksNav.$resetTrigger) { _ in
            if hasReceivedTrigger {
                dismiss()
            } else {
                hasReceivedTrigger = true
            }
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
                Button(action: backToBooks) {
                    Image(systemName: "book.closed")
                }
            }
        }
    }

    private func handleSearchResult(_ result: BibleSearchResult) {
        switch result.type {
        case .book:
            // When selecting another book, clear any pending chapter
            // navigation to prevent unintended pushes
            selectedChapter = nil
            selectedBook = result.book
            searchManager.clearSearch()
        case .chapter:
            selectedChapter = (result.book, result.chapter ?? 1, nil)
            searchManager.clearSearch()
        case .verse:
            selectedChapter = (result.book, result.chapter ?? 1, result.verse)
            searchManager.clearSearch()
        }
    }

    private func backToBooks() {
        booksNav.popToRoot()
    }
}

