import Foundation
import SwiftUI

/// Enum representing the available tabs in the application.
enum AppTab: Hashable {
    case home
    case books
    case study
}

/// Observable object that stores the currently selected tab.
class TabSelectionManager: ObservableObject {
    @Published var selection: AppTab = .home
}
