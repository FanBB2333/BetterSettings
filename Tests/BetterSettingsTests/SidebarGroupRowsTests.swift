import XCTest
@testable import BetterSettings

@MainActor
final class SidebarGroupRowsTests: XCTestCase {

    private func tab(_ id: String, _ group: String?) -> SettingsTab {
        SettingsTab(id: id, title: id, icon: "gear", group: group)
    }

    func testHeaderPrecedesEachRunOfAGroup() {
        let rows = SettingsSidebarViewController.tabRows(for: [
            tab("general", "App"), tab("huds", "App"),
            tab("output", "Audio"),
            tab("license", nil),
        ])
        XCTAssertEqual(rows, [
            .header("App"), .tab("general"), .tab("huds"),
            .header("Audio"), .tab("output"),
            .tab("license"),
        ])
    }

    func testUngroupedTabsHaveNoHeaders() {
        let rows = SettingsSidebarViewController.tabRows(for: [tab("a", nil), tab("b", nil)])
        XCTAssertEqual(rows, [.tab("a"), .tab("b")])
    }
}
