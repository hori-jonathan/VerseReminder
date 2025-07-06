import Foundation
import SwiftUI

/// Destinations for the Books navigation stack.
enum BooksRoute: Hashable {
    case expandedBook(String)
    case chapter(bookId: String, chapter: Int, highlight: Int?)
}

/// Observable object managing navigation within the Books tab.
class BooksNavigationManager: ObservableObject {
    /// The navigation path for the Books stack.
    @Published var path = NavigationPath()

    /// Push a chapter onto the stack and switch to the Books tab.
    func openChapter(bookId: String, chapter: Int, highlight: Int? = nil,
                     tabManager: TabSelectionManager) {
        tabManager.selection = .books
        path.append(BooksRoute.chapter(bookId: bookId, chapter: chapter, highlight: highlight))
    }

    /// Return to the root Books view and select the Books tab.
    func popToRoot(tabManager: TabSelectionManager) {
        tabManager.selection = .books
        path = NavigationPath()
    }
}
