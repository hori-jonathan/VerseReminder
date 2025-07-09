import XCTest

@MainActor
final class FastlaneSnapshotTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        setupSnapshot(app)
        app.launchArguments.append("--fastlane-snapshot")
        app.launch()
        XCUIDevice.shared.orientation = .portrait
    }

    func testHomeDashboardReadingProgress() {
        snapshot("01HomeDashboard")
    }

    func testChapterReadingScreen() {
        app.tabBars.buttons["Books"].tap()
        snapshot("02ChapterReading")
    }

    func testSearchAndBookNavigation() {
        app.tabBars.buttons["Books"].tap()
        snapshot("03SearchNavigation")
    }

    func testReadingPlanCreator() {
        app.tabBars.buttons["Home"].tap()
        app.buttons["Edit Plan"].tap()
        snapshot("04PlanCreator")
        app.navigationBars.buttons["Close"].tap()
    }

    func testStudyTabNotesBookmarks() {
        app.tabBars.buttons["Study"].tap()
        snapshot("05StudyNotes")
    }

    func testQuickSettingsPanel() {
        app.tabBars.buttons["Home"].tap()
        app.buttons["Settings"].tap()
        snapshot("06QuickSettings")
        app.navigationBars.buttons["Back"].tap()
    }

    func testFirstTimeSetupFlow() {
        snapshot("07FirstTimeSetup")
    }

    func testNotificationReminders() {
        snapshot("08NotificationPermission")
    }

    func testContactUsForm() {
        app.tabBars.buttons["Home"].tap()
        app.buttons["Contact Us"].tap()
        snapshot("09ContactForm")
        app.navigationBars.buttons["Back"].tap()
    }

    func testAdvancedSettingsAndAccountOptions() {
        app.tabBars.buttons["Home"].tap()
        app.buttons["Settings"].tap()
        snapshot("10AdvancedSettings")
    }
}
