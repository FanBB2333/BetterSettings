import AppKit
import XCTest
@testable import BetterSettings

/// A row's subtitle lives in a fixed-height, `clipsToBounds` container whose
/// height is measured from the text, so the measurement has to use the width the
/// label is actually laid out in. The row is wider than its text column by the
/// icon, the stack spacing and the accessory: measure against the row and a
/// subtitle that wraps inside that band is reported one line short, then loses
/// that line to the clip. Longer translations of a fitting English string land
/// in exactly that band, so this is a localization bug as much as a layout one.
///
/// The measurement width is observable: it is published as the label's
/// `preferredMaxLayoutWidth`.
@MainActor
final class SettingsRowSubtitleTests: XCTestCase {

    func testSubtitleIsMeasuredAtTheWidthItIsLaidOutIn() async throws {
        // Long enough to wrap in any column this row can get, so the measured
        // width is the column's real width rather than the text's own.
        let subtitle = String(repeating: "wrap this subtitle onto several lines ", count: 6)
        let row = SettingsRowView(icon: "gear", title: "Defaults for every shortcut",
                                  subtitle: subtitle, accessory: NSSwitch())

        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 420, height: 200),
                              styleMask: [.titled], backing: .buffered, defer: true)
        let host = NSView(frame: NSRect(x: 0, y: 0, width: 420, height: 200))
        window.contentView = host
        host.addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            row.topAnchor.constraint(equalTo: host.topAnchor),
        ])
        // The real column width is only known once the row is in a window, so
        // the height resolution runs a run-loop turn later — and settling the
        // height changes the column width again, so let it converge.
        for _ in 0..<8 {
            host.layoutSubtreeIfNeeded()
            await Task.yield()
        }
        host.layoutSubtreeIfNeeded()

        let label = try XCTUnwrap(subtitleLabel(in: row), "subtitle label not found")
        let container = try XCTUnwrap(label.superview)

        XCTAssertLessThan(container.bounds.width, row.bounds.width,
                          "row is not wider than its text column — fixture is meaningless")
        XCTAssertGreaterThan(label.bounds.height, (label.font?.boundingRectForFont.height ?? 0) * 1.5,
                             "fixture did not wrap")
        XCTAssertEqual(label.preferredMaxLayoutWidth, container.bounds.width, accuracy: 1,
                       "subtitle height was measured against the wrong view's width")
    }

    /// The subtitle is the smaller of the row's two labels.
    private func subtitleLabel(in row: SettingsRowView) -> NSTextField? {
        var fields: [NSTextField] = []
        func walk(_ view: NSView) {
            for subview in view.subviews {
                if let field = subview as? NSTextField { fields.append(field) }
                walk(subview)
            }
        }
        walk(row)
        return fields.min { ($0.font?.pointSize ?? 0) < ($1.font?.pointSize ?? 0) }
    }
}
