import Foundation
import SwiftUI

/// Observable object that allows views in the Books navigation stack
/// to programmatically pop back to the root "Books" page.
class BooksNavigationManager: ObservableObject {
    /// Changing this value notifies all views to dismiss themselves.
    @Published private(set) var resetTrigger: Int = 0

    /// Call to trigger a pop-to-root of all active views in the Books stack.
    func popToRoot() {
        // Increment the trigger which will be observed by each view
        // and cause it to call `dismiss()`.
        resetTrigger += 1
    }
}
