import XCTest

/// Reproduces the reported bug: demo login -> sign out -> log in again
/// shouldn't get stuck. Each step attaches a screenshot so a failure shows
/// exactly which screen the app was stuck on.
final class SignInOutFlowUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func attachScreenshot(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testDemoSignInSignOutSignInAgain() throws {
        let app = XCUIApplication()
        // Force a clean, signed-out start regardless of a session
        // persisted from a previous run (session persistence itself is
        // correct/intended behavior — this flag exists only so the test
        // has a deterministic starting point).
        app.launchArguments = ["UITEST_RESET_SESSION"]
        app.launch()

        // 1. Land on LoginView, enter the demo account.
        let demoButton = app.buttons["Ver demo (sin registro)"]
        XCTAssertTrue(demoButton.waitForExistence(timeout: 10), "No apareció el botón de demo")
        attachScreenshot(app, name: "01-login-screen")
        demoButton.tap()

        // 2. Should reach the tab bar (inHousehold) within a generous timeout
        // (covers profile fetch + membership fetch + household fetch).
        let inicioTab = app.tabBars.buttons["Inicio"]
        XCTAssertTrue(inicioTab.waitForExistence(timeout: 20), "No se llegó al TabView tras entrar en la demo")
        attachScreenshot(app, name: "02-in-household-after-demo-login")

        // 3. Open settings (gear button) and sign out.
        let settingsButton = app.buttons["Ajustes"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 10), "No apareció el botón de Ajustes")
        settingsButton.tap()

        let signOutButton = app.buttons["Cerrar sesión"]
        XCTAssertTrue(signOutButton.waitForExistence(timeout: 10), "No apareció el botón de Cerrar sesión")
        attachScreenshot(app, name: "03-account-settings-before-sign-out")
        signOutButton.tap()

        // 4. Should be back at LoginView.
        let demoButtonAgain = app.buttons["Ver demo (sin registro)"]
        let backAtLogin = demoButtonAgain.waitForExistence(timeout: 20)
        attachScreenshot(app, name: "04-after-sign-out")
        XCTAssertTrue(backAtLogin, "Tras cerrar sesión no volvió a la pantalla de login (aquí está el bug reportado)")

        // 5. Log in with the demo account again — this is the exact repro:
        // does a second sign-in cycle in the same process work?
        demoButtonAgain.tap()
        let inicioTabAgain = app.tabBars.buttons["Inicio"]
        let backInHousehold = inicioTabAgain.waitForExistence(timeout: 20)
        attachScreenshot(app, name: "05-after-second-demo-login")
        XCTAssertTrue(backInHousehold, "Tras volver a entrar en la demo no se llegó al TabView (bug reproducido)")
    }
}
