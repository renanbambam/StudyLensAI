import XCTest

/// Smoke tests for app launch and tab navigation.
/// The camera itself cannot run in the simulator, so the scan flow is covered
/// up to the camera boundary; OCR/AI logic is covered by unit tests.
final class ScanFlowUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testAppLaunchesToDeckList() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["Decks"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.tabBars.buttons["Scan"].exists)
        XCTAssertTrue(app.tabBars.buttons["Stats"].exists)
    }

    func testScanTabShowsScanCallToAction() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        // Dismiss the first-launch API key sheet if it appears.
        let laterButton = app.buttons["Later"]
        if laterButton.waitForExistence(timeout: 3) {
            laterButton.tap()
        }

        app.tabBars.buttons["Scan"].tap()
        XCTAssertTrue(app.buttons["Scan Notes"].waitForExistence(timeout: 5))
    }
}
