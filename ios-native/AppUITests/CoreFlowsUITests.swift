import XCTest

/// Regression coverage for the shopping-list CRUD flow against the real
/// demo household — adds a uniquely-named item, confirms it shows up, then
/// deletes it so the shared demo data stays clean for other testers.
final class CoreFlowsUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAddAndDeleteShoppingItem() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_RESET_SESSION"]
        app.launch()

        let demoButton = app.buttons["Ver demo (sin registro)"]
        XCTAssertTrue(demoButton.waitForExistence(timeout: 10), "No apareció el botón de demo")
        demoButton.tap()

        let compraTab = app.tabBars.buttons["Compra"]
        XCTAssertTrue(compraTab.waitForExistence(timeout: 20), "No se llegó al TabView")
        compraTab.tap()

        let itemName = "UITest-\(Int(Date().timeIntervalSince1970))"
        let nameField = app.textFields["Leche"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 10), "No apareció el campo de nombre del artículo")
        nameField.tap()
        nameField.typeText(itemName)

        let addButton = app.buttons["Añadir a la lista"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        let addedRow = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", itemName)).firstMatch
        XCTAssertTrue(addedRow.waitForExistence(timeout: 10), "El artículo añadido no apareció en la lista")

        // Clean up: swipe-to-delete the row we just created.
        addedRow.swipeLeft()
        let deleteButton = app.buttons["Quitar"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5), "No apareció el botón de Quitar al deslizar")
        deleteButton.tap()

        let stillThere = addedRow.waitForExistence(timeout: 3)
        XCTAssertFalse(stillThere, "El artículo de prueba no se borró correctamente")
    }
}
