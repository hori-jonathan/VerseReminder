import SwiftUI

struct BookmarksView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var booksNav: BooksNavigationManager
    @Environment(\.dismiss) private var dismiss

    @State private var verses: [Verse] = []

    var body: some View {
        NavigationView {
            List {
                ForEach(verses, id: \.id) { verse in
                    NavigationLink(destination: ChapterView(chapterId: referencePrefix(for: verse.id), bibleId: authViewModel.profile.bibleId, highlightVerse: Int(verse.verseNumber))) {
                        VStack(alignment: .leading) {
                            Text(verse.reference)
                                .font(.headline)
                            Text(verse.cleanedText)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .contextMenu {
                        Button("Remove") {
                            authViewModel.removeBookmark(verse.id)
                            loadVerses()
                        }
                    }
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("Bookmarks")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear(perform: loadVerses)
        }
    }

    private func referencePrefix(for id: String) -> String {
        let parts = id.split(separator: ".")
        guard parts.count >= 2 else { return id }
        return parts[0] + "." + parts[1]
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            authViewModel.removeBookmark(verses[index].id)
        }
        loadVerses()
    }

    private func loadVerses() {
        verses = []
        let ids = authViewModel.profile.bookmarks
        for id in ids {
            BibleAPI.shared.fetchVerse(reference: id, bibleId: authViewModel.profile.bibleId) { result in
                if case .success(let verse) = result {
                    DispatchQueue.main.async {
                        verses.append(verse)
                    }
                }
            }
        }
    }
}

struct BookmarksView_Previews: PreviewProvider {
    static var previews: some View {
        BookmarksView()
            .environmentObject(AuthViewModel())
            .environmentObject(BooksNavigationManager())
    }
}
