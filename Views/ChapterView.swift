import SwiftUI

struct ChapterView: View {
    let chapterId: String        // e.g. "GEN.1"
    let bibleId: String          // e.g. "179568874c45066f-01"
    let highlightVerse: Int?

    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var verses: [Verse] = []
    @State private var error: String?
    @State private var isLoading = false
    @State private var highlightedVerseId: String? = nil
    @State private var isCompleted: Bool = false
    @State private var navigateToNext: (bookId: String, chapter: Int)? = nil

    // Heading components
    var bookName: String {
        // Optional: Map abbreviation to name, or just display abbreviation for now
        chapterId.components(separatedBy: ".").first ?? ""
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
                
                Text("\(bookName) \(chapterNumber)")
                    .font(.title2)
                    .bold()
                    .padding(.vertical, 8)
                
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
}

// MARK: - VerseRowView

struct VerseRowView: View {
    let verse: Verse
    let isHighlighted: Bool
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(verse.verseNumber)
                .bold()
                .frame(width: 26, alignment: .trailing)
                .foregroundColor(.secondary)
            Text(verse.cleanedText)
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 4)
        .background(isHighlighted ? Color.yellow.opacity(0.3) : Color.clear)
        .cornerRadius(6)
        .animation(.easeInOut(duration: 0.3), value: isHighlighted)
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

    var body: some View {
        Toggle(isOn: Binding(
            get: { isCompleted },
            set: { newVal in
                isCompleted = newVal
                onToggle(newVal)
            }
        )) {
            Text(isCompleted ? "Chapter Completed" : "Mark Chapter Complete")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
        .background(
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.15))
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.4))
                    .frame(width: dragOffset)
            }
        )
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = max(0, value.translation.width)
                }
                .onEnded { _ in
                    if dragOffset > 80 {
                        if !isCompleted {
                            isCompleted = true
                            onToggle(true)
                        }
                        onSwipeComplete()
                    }
                    dragOffset = 0
                }
        )
    }
}
