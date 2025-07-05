import Foundation
import SwiftUI

/// Observable object that allows views in the Books navigation stack
/// to programmatically pop back to the root "Books" page.
class BooksNavigationManager: ObservableObject {
    /// Changing this value notifies all views to dismiss themselves.
    @Published private(set) var resetTrigger: Int = 0

    /// Call to trigger a pop-to-root of all active views in the Books stack.
    ///
    /// To reliably unwind multiple levels of navigation we bump the
    /// `resetTrigger` several times with small delays. Each active view
    /// observes this value and dismisses itself when it changes. By
    /// staggering the increments we ensure that after the top-most view
    /// closes the next one receives a new trigger and so on.
    func popToRoot() {
        let steps = 5
        for i in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                self.resetTrigger += 1
            }
        }
    }
}
