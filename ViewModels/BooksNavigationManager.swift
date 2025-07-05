import Foundation
import SwiftUI

/// Observable object that allows views in the Books navigation stack
/// to programmatically pop back to the root "Books" page.
class BooksNavigationManager: ObservableObject {
    /// Changing this value notifies all views to dismiss themselves.
    @Published private(set) var resetTrigger: Int = 0

    /// Call to trigger a pop-to-root of all active views in the Books stack.
    ///
    /// Sends several sequential increments so that each active view
    /// in the stack receives a dismissal signal even if others are
    /// still animating out. This avoids the back button effect where
    /// only the top view closes.
    func popToRoot() {
        for step in 0..<5 { // support up to 5 stacked views
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(step) * 0.05) {
                self.resetTrigger += 1
            }
        }
    }
}
