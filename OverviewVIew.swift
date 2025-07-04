import SwiftUI

// MARK: - Search Models
enum BibleSearchResultType {
    case book
    case chapter
    case verse
}

struct BibleSearchResult: Identifiable {
    let id = UUID()
    let type: BibleSearchResultType
    let book: BibleBook
    let chapter: Int?
    let verse: Int?
    let title: String
    let content: String?
    let matchedText: String?
    
    var hierarchyPath: String {
        switch type {
        case .book:
            return book.name
        case .chapter:
            return "\(book.name) • Chapter \(chapter ?? 1)"
        case .verse:
            return "\(book.name) • \(chapter ?? 1):\(verse ?? 1)"
        }
    }
}

// MARK: - Search Manager
class BibleSearchManager: ObservableObject {
    @Published var searchText = ""
    @Published var searchResults: [BibleSearchResult] = []
    @Published var isSearching = false
    @Published var showingSearchResults = false
    
    private var searchTimer: Timer?
    private let allBooks: [BibleBook]
    
    init() {
        self.allBooks = (oldTestamentCategories + newTestamentCategories).flatMap { $0.books }
    }
    
    func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            showingSearchResults = false
            isSearching = false
            return
        }
        
        isSearching = true
        showingSearchResults = true
        
        var results: [BibleSearchResult] = []
        let query = searchText.lowercased()
        
        // Search books with fuzzy matching
        for book in allBooks {
            let bookName = book.name.lowercased()
            let similarity = bookName.similarityScore(to: query)
            if bookName.contains(query) || similarity > 0.5 {
                results.append(BibleSearchResult(
                    type: .book,
                    book: book,
                    chapter: nil,
                    verse: nil,
                    title: book.name,
                    content: "\(book.chapters) chapters",
                    matchedText: query
                ))
            }
        }
        
        // Search for chapter/verse references like "John 3" or "John 3:16"
        if let ref = parseReference(query) {
            results.append(BibleSearchResult(
                type: .chapter,
                book: ref.book,
                chapter: ref.chapter,
                verse: nil,
                title: "Chapter \(ref.chapter)",
                content: nil,
                matchedText: nil
            ))

            if let verse = ref.verse {
                results.append(BibleSearchResult(
                    type: .verse,
                    book: ref.book,
                    chapter: ref.chapter,
                    verse: verse,
                    title: "Verse \(verse)",
                    content: nil,
                    matchedText: nil
                ))
            }
        }
        
        // Sort results by relevance
        self.searchResults = results.sorted { result1, result2 in
            let score1 = calculateRelevanceScore(result1, query: query)
            let score2 = calculateRelevanceScore(result2, query: query)
            return score1 > score2
        }

        // Prefetch verse content for verse results
        for (index, result) in searchResults.enumerated() where result.type == .verse {
            if let chapter = result.chapter, let verse = result.verse {
                let ref = "\(result.book.id).\(chapter).\(verse)"
                BibleAPI.shared.fetchVerse(reference: ref, bibleId: defaultBibleId) { res in
                    if case .success(let verseObj) = res {
                        DispatchQueue.main.async {
                            if index < self.searchResults.count {
                                self.searchResults[index].content = verseObj.cleanedText
                            }
                        }
                    }
                }
            }
        }
        
        isSearching = false
    }
    
    private func calculateRelevanceScore(_ result: BibleSearchResult, query: String) -> Int {
        var score = 0
        
        // Exact matches get highest score
        if result.title.lowercased() == query {
            score += 100
        } else if result.title.lowercased().contains(query) {
            score += 50
        }
        
        // Book name matches
        if result.book.name.lowercased().contains(query) {
            score += 30
        } else {
            let similarity = result.book.name.lowercased().similarityScore(to: query)
            score += Int(similarity * 20)
        }
        
        // Type priority: verses > chapters > books for specific searches
        switch result.type {
        case .verse: score += 20
        case .chapter: score += 15
        case .book: score += 10
        }
        
        return score
    }
    
    private func bestMatchingBook(for name: String) -> BibleBook? {
        let lower = name.lowercased()
        let best = allBooks.max { a, b in
            a.name.lowercased().similarityScore(to: lower) < b.name.lowercased().similarityScore(to: lower)
        }
        if let book = best, book.name.lowercased().similarityScore(to: lower) > 0.4 {
            return book
        }
        return nil
    }

    private func parseReference(_ query: String) -> (book: BibleBook, chapter: Int, verse: Int?)? {
        let pattern = #"^\s*(.+?)\s+(\d+)(?::(\d+))?\s*$"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let nsString = query as NSString
        let range = NSRange(location: 0, length: nsString.length)
        guard let match = regex?.firstMatch(in: query, options: [], range: range), match.numberOfRanges >= 3 else {
            return nil
        }

        let namePart = nsString.substring(with: match.range(at: 1))
        let chapter = Int(nsString.substring(with: match.range(at: 2))) ?? 0
        var verse: Int? = nil
        if match.numberOfRanges >= 4, match.range(at: 3).location != NSNotFound {
            verse = Int(nsString.substring(with: match.range(at: 3)))
        }

        if let book = bestMatchingBook(for: namePart) {
            return (book, chapter, verse)
        }
        return nil
    }
    
    func debounceSearch() {
        searchTimer?.invalidate()
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
            DispatchQueue.main.async {
                self.performSearch()
            }
        }
    }
    
    func clearSearch() {
        searchText = ""
        searchResults = []
        showingSearchResults = false
        searchTimer?.invalidate()
    }
}

// MARK: - Enhanced Overview View
struct OverviewView: View {
    @StateObject private var searchManager = BibleSearchManager()
    @State private var expandedBookId: String? = nil
    @State private var chaptersRead: [String: Set<Int>] = [:]
    @State private var chaptersBookmarked: [String: Set<Int>] = [:]
    @State private var lastRead: [String: (chapter: Int, verse: Int)] = [:]
    @State private var selectedChapter: (book: BibleBook, chapter: Int)? = nil
    @State private var scrollTargetBookId: String? = nil

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(searchManager: searchManager)
                
                if searchManager.showingSearchResults {
                    // Search Results View
                    SearchResultsView(
                        searchManager: searchManager,
                        onSelectResult: { result in
                            handleSearchResultSelection(result)
                        }
                    )
                } else {
                    // Main Bible Overview
                    ScrollViewReader { proxy in
                        List {
                        TestamentSection(
                            title: "Old Testament",
                            categories: oldTestamentCategories,
                            expandedBookId: $expandedBookId,
                            chaptersRead: $chaptersRead,
                            chaptersBookmarked: $chaptersBookmarked,
                            lastRead: $lastRead,
                            onSelectChapter: { book, chapter in
                                selectedChapter = (book, chapter)
                            }
                        )
                        TestamentSection(
                            title: "New Testament",
                            categories: newTestamentCategories,
                            expandedBookId: $expandedBookId,
                            chaptersRead: $chaptersRead,
                            chaptersBookmarked: $chaptersBookmarked,
                            lastRead: $lastRead,
                            onSelectChapter: { book, chapter in
                                selectedChapter = (book, chapter)
                            }
                        )
                        }
                        .listStyle(InsetGroupedListStyle())
                        .onChange(of: scrollTargetBookId) { id in
                            if let id = id {
                                withAnimation {
                                    proxy.scrollTo(id, anchor: .top)
                                }
                                scrollTargetBookId = nil
                            }
                        }
                    }
                }
                
                // NavigationLink for chapter navigation
                NavigationLink(
                    destination: selectedChapter.map {
                        ChapterView(
                            chapterId: "\($0.book.id).\($0.chapter)",
                            bibleId: defaultBibleId
                        )
                    },
                    isActive: Binding(
                        get: { selectedChapter != nil },
                        set: { if !$0 { selectedChapter = nil } }
                    )
                ) {
                    EmptyView()
                }
            }
            .navigationTitle("Books")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func handleSearchResultSelection(_ result: BibleSearchResult) {
        switch result.type {
        case .book:
            // Expand the book and scroll to it
            withAnimation(.easeInOut(duration: 0.5)) {
                expandedBookId = result.book.id
                scrollTargetBookId = result.book.id
            }
            searchManager.clearSearch()
            
        case .chapter:
            // Navigate to specific chapter
            selectedChapter = (result.book, result.chapter ?? 1)
            searchManager.clearSearch()
            
        case .verse:
            // Navigate to chapter containing the verse
            selectedChapter = (result.book, result.chapter ?? 1)
            searchManager.clearSearch()
        }
    }
}

// MARK: - Search Bar Component
struct SearchBar: View {
    @ObservedObject var searchManager: BibleSearchManager
    @State private var isEditing = false
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search books, chapters, verses...", text: $searchManager.searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onTapGesture {
                        isEditing = true
                    }
                    .onChange(of: searchManager.searchText) { _ in
                        if !searchManager.searchText.isEmpty {
                            searchManager.debounceSearch()
                        } else {
                            searchManager.clearSearch()
                        }
                    }
                
                if !searchManager.searchText.isEmpty {
                    Button(action: {
                        searchManager.clearSearch()
                        isEditing = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            if isEditing {
                Button("Cancel") {
                    searchManager.clearSearch()
                    isEditing = false
                    // Hide keyboard
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .foregroundColor(.blue)
                .transition(.move(edge: .trailing))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .animation(.easeInOut(duration: 0.2), value: isEditing)
    }
}

// MARK: - Search Results View
struct SearchResultsView: View {
    @ObservedObject var searchManager: BibleSearchManager
    let onSelectResult: (BibleSearchResult) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            if searchManager.isSearching {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Searching...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if searchManager.searchResults.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No results found")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Text("Try searching for a book name, chapter, or verse reference")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(searchManager.searchResults) { result in
                            SearchResultRow(result: result, query: searchManager.searchText) {
                                onSelectResult(result)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Search Result Row
struct SearchResultRow: View {
    let result: BibleSearchResult
    let query: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon based on type
                Image(systemName: iconName)
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    // Hierarchy path
                    Text(result.hierarchyPath)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Main title with highlight
                    highlightedText(result.title, query: query)
                        .font(.headline)
                        .multilineTextAlignment(.leading)
                    
                    // Content if available
                    if let content = result.content, !content.isEmpty {
                        Text(content)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineLimit(result.type == .verse ? 4 : 2)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(rowBackground)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func highlightedText(_ text: String, query: String) -> Text {
        let lowerText = text.lowercased()
        let lowerQuery = query.lowercased()
        if let range = lowerText.range(of: lowerQuery) {
            let start = text[..<range.lowerBound]
            let match = text[range]
            let end = text[range.upperBound...]
            return Text(String(start)) +
                Text(String(match)).foregroundColor(.accentColor) +
                Text(String(end))
        } else {
            return Text(text)
        }
    }

    private var rowBackground: Color {
        switch result.type {
        case .book: return Color.green.opacity(0.15)
        case .chapter: return Color.orange.opacity(0.15)
        case .verse: return Color.blue.opacity(0.15)
        }
    }
    
    private var iconName: String {
        switch result.type {
        case .book: return "book.closed"
        case .chapter: return "doc.text"
        case .verse: return "quote.bubble"
        }
    }
    
    private var iconColor: Color {
        switch result.type {
        case .book: return .green
        case .chapter: return .orange
        case .verse: return .blue
        }
    }
}

// MARK: - Testament Section (unchanged)
struct TestamentSection: View {
    let title: String
    let categories: [BookCategory]
    @Binding var expandedBookId: String?
    @Binding var chaptersRead: [String: Set<Int>]
    @Binding var chaptersBookmarked: [String: Set<Int>]
    @Binding var lastRead: [String: (chapter: Int, verse: Int)]
    let onSelectChapter: (BibleBook, Int) -> Void

    var body: some View {
        Section(header: Text(title).font(.title2).bold().padding(.top, 6)) {
            ForEach(categories) { category in
                CategorySection(
                    category: category,
                    expandedBookId: $expandedBookId,
                    chaptersRead: $chaptersRead,
                    chaptersBookmarked: $chaptersBookmarked,
                    lastRead: $lastRead,
                    onSelectChapter: onSelectChapter
                )
            }
        }
    }
}

// MARK: - Category Section (unchanged)
struct CategorySection: View {
    let category: BookCategory
    @Binding var expandedBookId: String?
    @Binding var chaptersRead: [String: Set<Int>]
    @Binding var chaptersBookmarked: [String: Set<Int>]
    @Binding var lastRead: [String: (chapter: Int, verse: Int)]
    let onSelectChapter: (BibleBook, Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(category.name)
                .font(.headline)
                .padding(.vertical, 6)
                .padding(.leading, 2)
            ForEach(category.books) { book in
                BookDropdownCell(
                    book: book,
                    isExpanded: expandedBookId == book.id,
                    expand: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            expandedBookId = (expandedBookId == book.id) ? nil : book.id
                        }
                    },
                    chaptersRead: chaptersRead[book.id] ?? [],
                    chaptersBookmarked: chaptersBookmarked[book.id] ?? [],
                    lastRead: lastRead[book.id],
                    onContinue: {
                        let next = lastRead[book.id]?.chapter ?? 1
                        onSelectChapter(book, next)
                    },
                    onSelectChapter: { chapter in
                        onSelectChapter(book, chapter)
                    }
                )
                .listRowInsets(EdgeInsets())
                .id(book.id)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Book Dropdown Cell (unchanged)
struct BookDropdownCell: View {
    let book: BibleBook
    let isExpanded: Bool
    let expand: () -> Void
    let chaptersRead: Set<Int>
    let chaptersBookmarked: Set<Int>
    let lastRead: (chapter: Int, verse: Int)?
    let onContinue: () -> Void
    let onSelectChapter: (Int) -> Void

    @State private var showContent: Bool = false
    private let dropdownHeight: CGFloat = 120

    var progress: Double {
        guard book.chapters > 0 else { return 0 }
        return Double(chaptersRead.count) / Double(book.chapters)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // HEADER ROW: always present
            Button(action: expand) {
                HStack {
                    Text(book.name)
                        .font(.body)
                        .padding(.vertical, 14)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.secondary)
                        .padding(.trailing, 12)
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: isExpanded ? 20 : 12)
                        .fill(isExpanded ? Color(.secondarySystemFill).opacity(0.5) : .clear)
                        .animation(.easeInOut(duration: 0.5), value: isExpanded)
                )
            }
            .buttonStyle(PlainButtonStyle())

            // DROPDOWN: fixed space, fades in/out
            ZStack {
                if showContent {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .center, spacing: 16) {
                            ZStack {
                                Circle()
                                    .stroke(Color.green.opacity(0.16), lineWidth: 6)
                                    .frame(width: 36, height: 36)
                                Circle()
                                    .trim(from: 0, to: progress)
                                    .stroke(Color.green, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                                    .rotationEffect(.degrees(-90))
                                    .frame(width: 36, height: 36)
                                    .animation(.easeInOut(duration: 0.7), value: progress)
                                Text("\(Int(progress * 100))%")
                                    .font(.caption2).bold()
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(chaptersRead.count) of \(book.chapters) chapters read")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Button(action: onContinue) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "arrow.right.circle.fill")
                                        if let last = lastRead {
                                            Text("Continue: Ch \(last.chapter)\(last.verse > 0 ? ":\(last.verse)" : "")")
                                        } else {
                                            Text("Start Book")
                                        }
                                    }
                                    .font(.footnote)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 5)
                                    .background(Color.green)
                                    .cornerRadius(8)
                                }
                                .padding(.top, 2)
                            }
                            Spacer()
                        }
                        // Chapter selector: scrollable horizontal
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(1...book.chapters, id: \.self) { chapter in
                                    Button(action: { onSelectChapter(chapter) }) {
                                        ZStack {
                                            Text("\(chapter)")
                                                .font(.footnote)
                                                .frame(width: 28, height: 28)
                                                .background(
                                                    chaptersRead.contains(chapter)
                                                        ? Color.blue.opacity(0.85)
                                                        : Color.red.opacity(0.13)
                                                )
                                                .foregroundColor(chaptersRead.contains(chapter) ? .white : .primary)
                                                .clipShape(Circle())
                                                .overlay(
                                                    Circle()
                                                        .stroke(chaptersRead.contains(chapter) ? Color.blue : Color.red, lineWidth: 1.2)
                                                )
                                            if chaptersBookmarked.contains(chapter) {
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
                            .padding(.leading, 6)
                            .padding(.vertical, 2)
                            .frame(minHeight: 40, maxHeight: 40)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 10)
                    .padding(.bottom, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.08), radius: 6, y: 2)
                    )
                    .opacity(showContent ? 1 : 0)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.33), value: showContent)
                }
            }
            .frame(height: isExpanded ? dropdownHeight : 0)
            .clipped()
            .animation(.easeInOut(duration: 0.54), value: isExpanded)
            .onChange(of: isExpanded) { expanded in
                if expanded {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        withAnimation(.easeInOut(duration: 0.3)) { showContent = true }
                    }
                } else {
                    withAnimation(.easeInOut(duration: 0.2)) { showContent = false }
                }
            }
            .onAppear {
                if isExpanded {
                    showContent = true
                }
            }
        }
        .background(Color.clear)
    }
}
