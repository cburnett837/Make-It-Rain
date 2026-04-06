//
//  MakeItRainUITestsLaunchTests.swift
//  MakeItRainUITests
//
//  Created by Cody Burnett on 3/30/26.
//

import XCTest

final class MakeItRainUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

//
//final class MultiSimulatorLaunchUITests: XCTestCase {
//    func testLaunchAndStayOpen() throws {
//        let app = XCUIApplication()
//
//        // Optional: tell the app it's running in a stress test
//        app.launchArguments += ["--ui-stress-test"]
//
//        app.launch()
//
//        //XCTAssertEqual(app.state, .runningForeground)
//
//        // Keep the app open long enough to overlap across simulators
//        //sleep(45)
//    }
//}
//
//
//import XCTest

final class MultiSimulatorLaunchUITests: XCTestCase {
    func testOpenFromHomeScreen() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let app = XCUIApplication()
        app.launch()
        let holdOpen = expectation(description: "Keep app open")
        wait(for: [holdOpen], timeout: 60)
    }
}
