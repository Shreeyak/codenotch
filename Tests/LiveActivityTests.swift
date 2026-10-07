import XCTest
@testable import Codenotch

/// "Show live activity" stops work in progress being drawn, and nothing else:
/// the ring loses its arc, the hover card keeps its sessions, and the choice
/// outlives a relaunch.
@MainActor
final class LiveActivityTests: XCTestCase {
    private let claude = ProviderSnapshot(id: "claude", displayName: "Claude", glyph: .claude,
        fidelity: .official, status: .ok,
        windows: [LimitWindow(id: "session", label: "Session", usedFraction: 0.4)])

    private func working(_ model: NotchViewModel) {
        model.sessions[claude.providerID] = [AgentSession(id: "s1", name: "s1", detail: "Terminal",
                                                          state: .busy, waitingFor: nil, since: Date())]
    }

    func testTheRingDrawsWorkByDefault() {
        let model = NotchViewModel()
        working(model)
        XCTAssertEqual(model.ringActivity(for: claude)?.state, .working)
    }

    func testSwitchedOffTheRingDrawsNothingAndTheCardKeepsItsSessions() {
        let model = NotchViewModel()
        working(model)
        model.showsLiveActivity = false
        XCTAssertNil(model.ringActivity(for: claude))
        XCTAssertEqual(model.activity(for: claude)?.sessions.count, 1)
    }

    func testTheChoiceIsOnUntilTurnedOffAndThenSurvivesARelaunch() {
        let name = "LiveActivityTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        XCTAssertTrue(Preferences(defaults: defaults).showsLiveActivity)

        Preferences(defaults: defaults).showsLiveActivity = false

        XCTAssertFalse(Preferences(defaults: UserDefaults(suiteName: name)!).showsLiveActivity)
    }
}
