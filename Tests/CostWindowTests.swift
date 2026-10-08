import XCTest
@testable import Codenotch

/// The card's "what used it" rows are built from samples of the limit, each
/// filed under the allowance it measures. A sample filed under the wrong one
/// lands in a period of the wrong length, and the week's rows stay empty.
@MainActor
final class CostWindowTests: XCTestCase {
    /// Pro Lite has a weekly limit and no five-hour one, and the server sends
    /// that week as Codex's first window.
    func testAWeekSentAsCodexsFirstWindowIsFiledAsTheWeek() throws {
        let payload = """
        {"plan_type":"prolite","rate_limit":{"allowed":true,"limit_reached":false,
         "primary_window":{"used_percent":22,"limit_window_seconds":604800,
                           "reset_after_seconds":486911,"reset_at":1791949122},
         "secondary_window":null},
         "code_review_rate_limit":null,"additional_rate_limits":null}
        """
        let windows = try CodexUsage.windows(from: Data(payload.utf8))
        let primary = try XCTUnwrap(windows.first { $0.id == "primary" })
        XCTAssertEqual(CostModel.costWindow(for: primary), .weekly)
    }

    func testAFiveHourFirstWindowIsStillTheSession() throws {
        let payload = """
        {"plan_type":"plus","rate_limit":{"allowed":true,"limit_reached":false,
         "primary_window":{"used_percent":10,"limit_window_seconds":18000,"reset_after_seconds":3600},
         "secondary_window":{"used_percent":40,"limit_window_seconds":604800,"reset_after_seconds":86400}}}
        """
        let windows = try CodexUsage.windows(from: Data(payload.utf8))
        let filed = Dictionary(uniqueKeysWithValues: windows.map { ($0.id, CostModel.costWindow(for: $0)) })
        XCTAssertEqual(filed["primary"], .session)
        XCTAssertEqual(filed["secondary"], .weekly)
    }

    /// Archives written before windows recorded their length keep the old
    /// reading of the id.
    func testAWindowWithNoStatedLengthIsReadFromItsID() {
        XCTAssertEqual(CostModel.costWindow(for: LimitWindow(id: "primary", label: "")), .session)
        XCTAssertEqual(CostModel.costWindow(for: LimitWindow(id: "weekly_all", label: "")), .weekly)
        XCTAssertEqual(CostModel.costWindow(for: LimitWindow(id: "team-credits", label: "")), .credits)
        XCTAssertNil(CostModel.costWindow(for: LimitWindow(id: "spark", label: "")))
    }
}
