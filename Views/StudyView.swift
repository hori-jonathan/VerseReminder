import SwiftUI

struct StudyView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var booksNav: BooksNavigationManager
    @State private var bookmarkedVerses: [Verse] = []

    private var allBooks: [BibleBook] {
        (oldTestamentCategories + newTestamentCategories).flatMap { $0.books }
    }

    var body: some View {
        NavigationView {
            List {
                if !bookmarkedVerses.isEmpty {
                    Section(header: Text("Your Bookmarks")) {
                        ForEach(bookmarkedVerses, id: \.id) { verse in
                            NavigationLink(
                                destination: ChapterView(
                                    chapterId: referencePrefix(for: verse.id),
                                    bibleId: authViewModel.profile.bibleId,
                                    highlightVerse: Int(verse.verseNumber)
                                )
                            ) {
                                VStack(alignment: .leading) {
                                    Text(verse.reference).font(.headline)
                                    Text(verse.cleanedText)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .contextMenu {
                                Button("Remove") {
                                    authViewModel.removeBookmark(verse.id)
                                    loadBookmarks()
                                }
                            }
                        }
                        .onDelete(perform: deleteBookmark)
                    }
                }

                let notes = noteEntries()
                let grouped = Dictionary(grouping: notes) { $0.bookId }
                ForEach(allBooks.filter { grouped[$0.id] != nil }.sorted { $0.order < $1.order }, id: \.id) { book in
                    if let entries = grouped[book.id] {
                        Section(header: Text(book.name)) {
                            ForEach(entries) { entry in
                                NavigationLink(
                                    destination: ChapterView(
                                        chapterId: entry.chapterId,
                                        bibleId: authViewModel.profile.bibleId,
                                        highlightVerse: entry.verse
                                    )
                                ) {
                                    VStack(alignment: .leading) {
                                        Text(entry.displayRef).font(.headline)
                                        Text(entry.text)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Study")
            .onAppear(perform: loadBookmarks)
        }
    }

    private func referencePrefix(for id: String) -> String {
        let parts = id.split(separator: ".")
        guard parts.count >= 2 else { return id }
        return parts[0] + "." + parts[1]
    }

    private func loadBookmarks() {
        bookmarkedVerses = []
        for id in authViewModel.profile.bookmarks {
            BibleAPI.shared.fetchVerse(reference: id) { result in
                if case .success(let verse) = result {
                    DispatchQueue.main.async { bookmarkedVerses.append(verse) }
                }
            }
        }
    }

    private func deleteBookmark(at offsets: IndexSet) {
        for index in offsets {
            authViewModel.removeBookmark(bookmarkedVerses[index].id)
        }
        loadBookmarks()
    }

    private func noteEntries() -> [NoteEntry] {
        var entries: [NoteEntry] = []
        for (cid, text) in authViewModel.profile.chapterNotes {
            let parts = cid.split(separator: ".")
            if parts.count == 2, let chap = Int(parts[1]) {
                entries.append(NoteEntry(bookId: String(parts[0]), chapter: chap, verse: nil, text: text))
            }
        }
        for (cid, verses) in authViewModel.profile.verseNotes {
            let parts = cid.split(separator: ".")
            if parts.count == 2, let chap = Int(parts[1]) {
                for (v, text) in verses {
                    if let vnum = Int(v) {
                        entries.append(NoteEntry(bookId: String(parts[0]), chapter: chap, verse: vnum, text: text))
                    }
                }
            }
        }
        return entries.sorted { a, b in
            if a.bookId == b.bookId {
                if a.chapter == b.chapter { return (a.verse ?? 0) < (b.verse ?? 0) }
                return a.chapter < b.chapter
            }
            let oa = allBooks.first { $0.id == a.bookId }?.order ?? 0
            let ob = allBooks.first { $0.id == b.bookId }?.order ?? 0
            return oa < ob
        }
    }
}

private struct NoteEntry: Identifiable {
    let id = UUID()
    let bookId: String
    let chapter: Int
    let verse: Int?
    let text: String

    var chapterId: String { "\(bookId).\(chapter)" }
    var displayRef: String {
        if let v = verse {
            return "\(chapter):\(v)"
        } else {
            return "Chapter \(chapter)"
        }
    }
}

struct StudyView_Previews: PreviewProvider {
    static var previews: some View {
        StudyView()
            .environmentObject(AuthViewModel())
            .environmentObject(BooksNavigationManager())
    }
}

