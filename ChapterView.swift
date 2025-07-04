import SwiftUI

struct ChapterView: View {
    let chapterId: String        // e.g. "GEN.1"
    let bibleId: String          // e.g. "179568874c45066f-01"
    let highlightVerse: Int?
    
    @State private var verses: [Verse] = []
    @State private var error: String?
    @State private var isLoading = false
    @State private var highlightedVerseId: String? = nil

    // Heading components
    var bookName: String {
        // Optional: Map abbreviation to name, or just display abbreviation for now
        chapterId.components(separatedBy: ".").first ?? ""
    }
    var chapterNumber: String {
        chapterId.components(separatedBy: ".").last ?? ""
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
    }
    
    // MARK: - Previous/Next chapter navigation
    func previousChapter() {
        // TODO: Implement navigation to previous chapter if you wish
    }
    func nextChapter() {
        // TODO: Implement navigation to next chapter if you wish
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
