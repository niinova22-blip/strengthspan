import XCTest

@MainActor
final class StrengthspanUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = false
    }

    private func launch(language: String, locale: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-AppleLanguages", "(\(language))", "-AppleLocale", locale]
        app.launch()
        return app
    }

    private func tap(_ identifier: String, in app: XCUIApplication) {
        let element = app.descendants(matching: .any)[identifier].firstMatch
        XCTAssertTrue(element.waitForExistence(timeout: 5), "Missing \(identifier)")
        if !element.isHittable {
            app.swipeUp()
        }
        element.tap()
    }

    /// Answers every onboarding step and lands on the Today tab.
    private func completeOnboarding(_ app: XCUIApplication) {
        tap("onboarding.next", in: app)
        for option in ["option.ageRange.age50to54", "option.activity.lightlyActive", "option.experience.new", "option.goal.stayIndependent"] {
            tap(option, in: app)
            tap("onboarding.next", in: app)
        }
        for weekday in 1...7 {
            tap("option.weekday.\(weekday)", in: app)
        }
        tap("onboarding.next", in: app)
        tap("option.sessionLength.10", in: app)
        tap("onboarding.next", in: app)
        tap("option.equipment.bodyweightOnly", in: app)
        tap("onboarding.next", in: app)
        for question in ["supervisedOnly", "chestPain", "dizziness", "recentSurgery", "recentFall", "jointPain", "movementLimitation"] {
            tap("screening.\(question).no", in: app)
        }
        tap("onboarding.next", in: app)
        tap("onboarding.next", in: app)
    }

    @MainActor
    func testOnboardingLeadsToTodayWithAWorkout() throws {
        let app = launch(language: "en", locale: "en_US")
        completeOnboarding(app)

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        XCTAssertEqual(tabBar.buttons.count, 3)
        // Every weekday was chosen, so there is a session today.
        XCTAssertTrue(app.buttons["today.workout.start"].waitForExistence(timeout: 5))

        tabBar.buttons["Progress"].tap()
        XCTAssertTrue(app.navigationBars["Progress"].waitForExistence(timeout: 2))
        tabBar.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testWorkoutCanBeStoppedSafely() throws {
        let app = launch(language: "en", locale: "en_US")
        completeOnboarding(app)

        tap("today.workout.start", in: app)
        tap("player.checkIn.ok", in: app)
        tap("player.setDone", in: app)
        tap("player.unwell", in: app)
        tap("safety.check.warningSigns", in: app)
        XCTAssertTrue(app.buttons["outcome.done"].waitForExistence(timeout: 5))
        tap("outcome.done", in: app)

        // Training is paused after warning signs.
        XCTAssertFalse(app.buttons["today.workout.start"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testFirstCapacityCheckIsFreeAndReassessmentNeedsPro() throws {
        let app = launch(language: "en", locale: "en_US")
        completeOnboarding(app)

        tap("today.assessment.start", in: app)
        tap("assessment.overview.start", in: app)
        // Skip the first four tests, measure overhead reach by hand.
        for _ in 0..<4 {
            tap("assessment.intro.skip", in: app)
        }
        tap("assessment.intro.manual", in: app)
        tap("assessment.reach.3", in: app)
        tap("assessment.result.save", in: app)
        tap("assessment.summary.save", in: app)
        tap("assessment.saved.done", in: app)

        // A second check is a Pro feature: the paywall opens instead.
        tap("today.assessment.start", in: app)
        XCTAssertTrue(app.buttons["paywall.close"].waitForExistence(timeout: 5))
        tap("paywall.close", in: app)

        app.tabBars.firstMatch.buttons["Progress"].tap()
        XCTAssertTrue(app.staticTexts["Arm fully overhead, beside my ear"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testLaunchesInTurkish() throws {
        let app = launch(language: "tr", locale: "tr_TR")
        let start = app.buttons["onboarding.next"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        XCTAssertEqual(start.label, "Başla")
    }
}
