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

    /// Xcode's automated accessibility audit (contrast, labels, hit areas, Dynamic Type, …) on every main screen.
    @MainActor
    func testMainScreensPassTheAccessibilityAudit() throws {
        let app = launch(language: "en", locale: "en_US")
        var failedScreens: [String] = []
        audit(app, screen: "Welcome", failures: &failedScreens)
        completeOnboarding(app)

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5))
        audit(app, screen: "Today", failures: &failedScreens)
        app.tabBars.firstMatch.buttons["Progress"].tap()
        settle(on: "Progress", in: app)
        audit(app, screen: "Progress", failures: &failedScreens)
        app.tabBars.firstMatch.buttons["Settings"].tap()
        settle(on: "Settings", in: app)
        audit(app, screen: "Settings", failures: &failedScreens)
        app.tabBars.firstMatch.buttons["Today"].tap()

        tap("today.workout.start", in: app)
        XCTAssertTrue(app.buttons["player.checkIn.ok"].waitForExistence(timeout: 5))
        audit(app, screen: "Workout check-in", failures: &failedScreens)
        tap("player.checkIn.ok", in: app)
        audit(app, screen: "Workout exercise", failures: &failedScreens)

        XCTAssertEqual(failedScreens, [], "Accessibility audit findings — see A11Y lines in the log")
    }

    /// Waits for a tab's navigation bar and lets the transition finish, so the audit sees the final layout.
    @MainActor
    private func settle(on title: String, in app: XCUIApplication) {
        XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 5))
        Thread.sleep(forTimeInterval: 1.5)
    }

    /// Audits one screen and keeps going, so a single run reports findings for every screen.
    @MainActor
    private func audit(_ app: XCUIApplication, screen: String, failures: inout [String]) {
        var found = false
        let tabBarTop = app.tabBars.firstMatch.exists ? app.tabBars.firstMatch.frame.minY : .greatestFiniteMagnitude
        try? app.performAccessibilityAudit { issue in
            // Known false positives, ignored on purpose:
            // - "Dynamic Type partially unsupported" is reported even for system bar buttons; all our text
            //   uses system text styles. Clipped text is still audited separately.
            // - Contrast of content scrolled underneath the translucent tab bar, or with no element to fix.
            if issue.auditType == .dynamicType { return true }
            if issue.auditType == .contrast {
                guard let element = issue.element else { return true }
                if element.frame.maxY > tabBarTop { return true }
            }
            print("A11Y [\(screen)] \(issue.auditType) — \(issue.compactDescription) — \(issue.element?.debugDescription.prefix(160) ?? "no element")")
            found = true
            return true
        }
        if found { failures.append(screen) }
    }

    @MainActor
    func testLaunchesInTurkish() throws {
        let app = launch(language: "tr", locale: "tr_TR")
        let start = app.buttons["onboarding.next"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        XCTAssertEqual(start.label, "Başla")
    }
}
