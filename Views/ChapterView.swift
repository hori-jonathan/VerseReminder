import SwiftUI

struct ChapterView: View {
    let chapterId: String        // e.g. "GEN.1"
    let bibleId: String          // e.g. "179568874c45066f-01"
    let highlightVerse: Int?

    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var booksNav: BooksNavigationManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var verses: [Verse] = []
    @State private var error: String?
    @State private var isLoading = false
    @State private var highlightedVerseId: String? = nil
    @State private var isCompleted: Bool = false
    @State private var navigateToNext: (bookId: String, chapter: Int)? = nil
    @State private var navigateToBook: BibleBook? = nil
    @StateObject private var searchManager = BibleSearchManager()
    @State private var showBookmarks = false
    @State private var showChapterNoteEditor = false

    // Heading components
    var bookName: String {
        let abbrev = chapterId.components(separatedBy: ".").first ?? ""
        return allBooks.first(where: { $0.id == abbrev })?.name ?? abbrev
    }
    var chapterNumber: String {
        chapterId.components(separatedBy: ".").last ?? ""
    }

    var chapterInt: Int {
        Int(chapterNumber) ?? 1
    }

    var bookId: String {
        chapterId.components(separatedBy: ".").first ?? ""
    }

    var allBooks: [BibleBook] {
        (oldTestamentCategories + newTestamentCategories).flatMap { $0.books }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Static Heading
            HStack {
                Button(action: previousChapter) {
                    Image(systemName: "chevron.left")
                }
                .padding(.trailing, 8)
                .disabled(isLoading)
                
                Spacer()
                
                Button(action: openExpandedBook) {
                    Text("\(bookName) \(chapterNumber)")
                        .font(.title2)
                        .bold()
                        .padding(.vertical, 8)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                Button(action: nextChapter) {
                    Image(systemName: "chevron.right")
                }
                .padding(.leading, 8)
                .disabled(isLoading)
            }
            .padding(.horizontal)
            
            Divider()
            
            if isLoading {
                ProgressView("Loading chapter...")
                    .padding()
            } else if let error = error {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 6) {
                            ForEach(verses, id: \.id) { verse in
                                VerseRowView(verse: verse, isHighlighted: verse.id == highlightedVerseId)
                                    .id(verse.id)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)

                        CompleteChapterToggle(
                            isCompleted: $isCompleted,
                            onToggle: { completed in
                                if completed {
                                    authViewModel.markChapterRead(bookId: bookId, chapter: chapterInt, verse: 0)
                                } else {
                                    authViewModel.unmarkChapterRead(bookId: bookId, chapter: chapterInt)
                                }
                            },
                            onSwipeComplete: {
                                markCompleteAndAdvance()
                            }
                        )
                        .padding(.vertical, 12)
                        .padding(.horizontal)
                    }
                    .onAppear {
                        highlightIfNeeded(using: proxy)
                    }
                    .onChange(of: verses) { _ in
                        highlightIfNeeded(using: proxy)
                    }
                }
            }
        }
        .onAppear(perform: loadChapter)
        .onReceive(booksNav.$resetTrigger.dropFirst()) { _ in
            dismiss()
        }
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
                    Button(action: { showChapterNoteEditor = true }) {
                        Image(systemName: "note.text")
                    }
                    Button(action: backToBooks) {
                        Image(systemName: "book.closed")
                    }
                }
            }
        }

        NavigationLink(
            destination: navigateToNext.map {
                ChapterView(
                    chapterId: "\($0.bookId).\($0.chapter)",
                    bibleId: bibleId,
                    highlightVerse: nil
                )
            },
            isActive: Binding(
                get: { navigateToNext != nil },
                set: { if !$0 { navigateToNext = nil } }
            )
        ) { EmptyView() }

        NavigationLink(
            destination: navigateToBook.map { book in
                ExpandedBookView(
                    book: book,
                    searchManager: searchManager,
                    chaptersRead: authViewModel.profile.chaptersRead.mapValues { Set($0) },
                    chaptersBookmarked: authViewModel.profile.chaptersBookmarked.mapValues { Set($0) },
                    lastRead: authViewModel.profile.lastRead.reduce(into: [String: (chapter: Int, verse: Int)]()) { partial, item in
                        partial[item.key] = (item.value["chapter"] ?? 1, item.value["verse"] ?? 0)
                    }
                ) { b, chapter in
                    navigateToNext = (b.id, chapter)
                }
            },
            isActive: Binding(
                get: { navigateToBook != nil },
                set: { if !$0 { navigateToBook = nil } }
            )
        ) { EmptyView() }

        .sheet(isPresented: $showBookmarks) {
            BookmarksView()
                .environmentObject(booksNav)
        }
        .sheet(isPresented: $showChapterNoteEditor) {
            NoteEditorView(
                text: authViewModel.chapterNote(for: chapterId) ?? "",
                title: "Note for \(bookName) \(chapterNumber)"
            ) { newText in
                authViewModel.setChapterNote(newText, chapterId: chapterId)
            }
        }
    }
    
    // MARK: - Previous/Next chapter navigation
    func previousChapter() {
        guard let currentBook = allBooks.first(where: { $0.id == bookId }),
              let index = allBooks.firstIndex(of: currentBook) else { return }
        var newBook = currentBook
        var chapter = chapterInt - 1
        if chapter < 1 {
            let prevIndex = index - 1
            guard prevIndex >= 0 else { return }
            newBook = allBooks[prevIndex]
            chapter = newBook.chapters
        }
        navigateToNext = (newBook.id, chapter)
    }

    func nextChapter() {
        guard let currentBook = allBooks.first(where: { $0.id == bookId }),
              let index = allBooks.firstIndex(of: currentBook) else { return }
        var newBook = currentBook
        var chapter = chapterInt + 1
        if chapter > currentBook.chapters {
            let nextIndex = index + 1
            guard nextIndex < allBooks.count else { return }
            newBook = allBooks[nextIndex]
            chapter = 1
        }
        navigateToNext = (newBook.id, chapter)
    }
    
    // MARK: - Load chapter
    private func loadChapter() {
        isLoading = true
        error = nil
        verses = []
        
        let allIds = BibleAPI.shared.allVerseIds
        let chapterPrefix = chapterId + "."
        let chapterVerseIds = allIds.filter { $0.hasPrefix(chapterPrefix) }
        
        if chapterVerseIds.isEmpty {
            self.error = "No verses found for this chapter."
            self.isLoading = false
            return
        }
        
        // Sort verse IDs by numeric verse number
        let sortedIds = chapterVerseIds.sorted {
            let n1 = Int($0.components(separatedBy: ".").last ?? "") ?? 0
            let n2 = Int($1.components(separatedBy: ".").last ?? "") ?? 0
            return n1 < n2
        }
        
        var loadedVerses: [Verse] = Array(repeating: Verse(reference: "", content: "", contextURL: nil, id: ""), count: sortedIds.count)
        let group = DispatchGroup()
        for (i, vid) in sortedIds.enumerated() {
            group.enter()
            BibleAPI.shared.fetchVerse(reference: vid, bibleId: bibleId) { result in
                if case .success(let verse) = result {
                    loadedVerses[i] = verse
                }
                group.leave()
            }
        }
        group.notify(queue: .main) {
            self.verses = loadedVerses
            self.isLoading = false
            self.isCompleted = authViewModel.profile.chaptersRead[bookId]?.contains(chapterInt) ?? false
            authViewModel.updateLastRead(bookId: bookId, chapter: chapterInt, verse: highlightVerse ?? 0)
        }
    }

    private func highlightIfNeeded(using proxy: ScrollViewProxy) {
        guard highlightedVerseId == nil,
              let target = highlightVerse,
              let id = verses.first(where: { Int($0.verseNumber) == target })?.id else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.5)) {
                proxy.scrollTo(id, anchor: .center)
            }
            highlightedVerseId = id
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    highlightedVerseId = nil
                }
            }
        }
    }

    private func markCompleteAndAdvance() {
        if !isCompleted {
            isCompleted = true
            authViewModel.markChapterRead(bookId: bookId, chapter: chapterInt, verse: 0)
        }
        nextChapter()
    }

    private func backToBooks() {
        booksNav.popToRoot()
    }

    private func openExpandedBook() {
        if let book = allBooks.first(where: { $0.id == bookId }) {
            navigateToBook = book
        }
    }
}

// MARK: - VerseRowView

struct VerseRowView: View {
    let verse: Verse
    let isHighlighted: Bool
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showNoteEditor = false
    @State private var noteText = ""

    var isBookmarked: Bool {
        authViewModel.isBookmarked(verse.id)
    }

    var chapterId: String {
        let parts = verse.id.split(separator: ".")
        guard parts.count >= 2 else { return verse.id }
        return parts[0] + "." + parts[1]
    }

    var existingNote: String? {
        authViewModel.verseNote(for: chapterId, verse: Int(verse.verseNumber) ?? 0)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .trailing, spacing: 2) {
                Text(verse.verseNumber)
                    .bold()
                    .frame(width: 26, alignment: .trailing)
                    .foregroundColor(.secondary)
                if isBookmarked {
                    Image(systemName: "bookmark.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 10, height: 10)
                        .foregroundColor(.blue)
                }
            }
            Text(verse.cleanedText)
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 4)
        .background(isHighlighted ? Color.yellow.opacity(0.3) : Color.clear)
        .cornerRadius(6)
        .animation(.easeInOut(duration: 0.3), value: isHighlighted)
        .contextMenu {
            if isBookmarked {
                Button("Remove Bookmark") {
                    authViewModel.removeBookmark(verse.id)
                }
            } else {
                Button("Add Bookmark") {
                    authViewModel.addBookmark(verse.id)
                }
            }
            Button(existingNote == nil ? "Add Note" : "Edit Note") {
                noteText = existingNote ?? ""
                showNoteEditor = true
            }
            if existingNote != nil {
                Button("Remove Note") {
                    authViewModel.setVerseNote("", chapterId: chapterId, verse: Int(verse.verseNumber) ?? 0)
                }
            }
        }
        .sheet(isPresented: $showNoteEditor) {
            NoteEditorView(
                text: noteText,
                title: "Note for \(verse.reference)"
            ) { newText in
                authViewModel.setVerseNote(newText, chapterId: chapterId, verse: Int(verse.verseNumber) ?? 0)
            }
        }
    }
}

// MARK: - Verse Extensions

extension Verse {
    var verseNumber: String {
        id.components(separatedBy: ".").last ?? ""
    }

    var cleanedText: String {
        let stripped = content.stripHTML().trimmingCharacters(in: .whitespacesAndNewlines)
        // Remove leading number and possible space
        if let num = Int(verseNumber),
           stripped.hasPrefix("\(num) ") {
            return String(stripped.dropFirst("\(num) ".count))
        } else if let num = Int(verseNumber),
                  stripped.hasPrefix("\(num)") {
            return String(stripped.dropFirst("\(num)".count)).trimmingCharacters(in: .whitespaces)
        } else {
            return stripped
        }
    }
}

// MARK: - Complete Chapter Toggle
struct CompleteChapterToggle: View {
    @Binding var isCompleted: Bool
    let onToggle: (Bool) -> Void
    let onSwipeComplete: () -> Void

    @State private var dragOffset: CGFloat = 0

    private let height: CGFloat = 44

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Capsule()
                    .stroke(Color.black, lineWidth: 1)
                    .background(
                        Capsule()
                            .fill(isCompleted ? Color.black : Color.clear)
                    )

                Text(isCompleted ? "Completed" : "Complete Chapter")
                    .foregroundColor(isCompleted ? .white : .black)
                    .frame(maxWidth: .infinity)

                Circle()
                    .fill(Color.black)
                    .frame(width: height - 8, height: height - 8)
                    .offset(x: dragOffset - (geo.size.width / 2 - height / 2))
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = max(0, min(value.translation.width, geo.size.width - height))
                            }
                            .onEnded { _ in
                                if dragOffset > geo.size.width * 0.65 {
                                    if !isCompleted {
                                        isCompleted = true
                                        onToggle(true)
                                    }
                                    onSwipeComplete()
                                } else if dragOffset > geo.size.width * 0.1 {
                                    isCompleted.toggle()
                                    onToggle(isCompleted)
                                }
                                dragOffset = 0
                            }
                    )
                    .overlay(
                        Image(systemName: isCompleted ? "checkmark" : "chevron.right")
                            .foregroundColor(.white)
                    )
            }
            .frame(height: height)
        }
        .frame(height: height)
        .onTapGesture {
            isCompleted.toggle()
            onToggle(isCompleted)
        }
    }
}
