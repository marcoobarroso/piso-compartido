import XCTest

/// Not a regression test — a manual visual-QA/App-Store-screenshot tool.
/// Logs into the demo household and walks every tab, attaching a
/// screenshot of each so layout on a given simulator (small/large screen)
/// can be reviewed without driving the simulator by hand.
final class ScreenshotTourUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func shot(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testTourAllTabs() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_RESET_SESSION"]
        app.launch()

        let demoButton = app.buttons["Ver demo (sin registro)"]
        XCTAssertTrue(demoButton.waitForExistence(timeout: 10))
        demoButton.tap()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.buttons["Inicio"].waitForExistence(timeout: 20))
        shot(app, "tab-inicio")

        for tab in ["Gastos", "Tareas", "Compra", "Stats"] {
            let button = tabBar.buttons[tab]
            guard button.waitForExistence(timeout: 10) else { continue }
            button.tap()
            Thread.sleep(forTimeInterval: 1.5) // let async data load settle

            // Gastos/Tareas open on their "add" form — scroll past it so the
            // screenshot shows the actual balances/task list instead of an
            // empty-looking form (this is what App Store screenshots use).
            if tab == "Gastos" {
                app.swipeUp()
                Thread.sleep(forTimeInterval: 0.3)
            } else if tab == "Tareas" {
                app.swipeUp()
                Thread.sleep(forTimeInterval: 0.3)
            }
            shot(app, "tab-\(tab.lowercased())")

            if tab == "Tareas" {
                for subTab in ["Calendario", "Historial"] {
                    let segment = app.buttons[subTab]
                    guard segment.waitForExistence(timeout: 5) else { continue }
                    segment.tap()
                    Thread.sleep(forTimeInterval: 1)
                    shot(app, "tareas-\(subTab.lowercased())")
                }
            }
        }

        // Ajustes (sheet) — its toolbar button only lives on the Inicio tab.
        tabBar.buttons["Inicio"].tap()
        let settingsButton = app.buttons["Ajustes"]
        if settingsButton.waitForExistence(timeout: 5) {
            settingsButton.tap()
            Thread.sleep(forTimeInterval: 1)
            shot(app, "ajustes")
        }
    }
}
