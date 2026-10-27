import XCTest

final class StrengthspanUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchShowsThreeTabsAndTheyAreNavigable() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        XCTAssertEqual(tabBar.buttons.count, 3)

        tabBar.buttons["Progress"].tap()
        XCTAssertTrue(app.navigationBars["Progress"].waitForExistence(timeout: 2))

        tabBar.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 2))

        tabBar.buttons["Today"].tap()
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testLaunchesInTurkish() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-AppleLanguages", "(tr)", "-AppleLocale", "tr_TR"]
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["Bugün"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["İlerleme"].exists)
        XCTAssertTrue(app.tabBars.buttons["Ayarlar"].exists)
    }
}
