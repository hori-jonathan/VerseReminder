import Foundation
import SwiftUI

/// Observable object that allows views in the Books navigation stack
/// to programmatically pop back to the root "Books" page.
class BooksNavigationManager: ObservableObject {
    /// Changing this value notifies all views to dismiss themselves.
    @Published private(set) var resetTrigger: Int = 0

    /// Call to trigger a pop-to-root of all active views in the Books stack.
    ///
    /// Simply incrementing the trigger causes all subscribed views to
    /// dismiss themselves if the value differs from the one they observed on
    /// creation. This lets every active panel close simultaneously.
    func popToRoot() {
        resetTrigger += 1
    }
}
