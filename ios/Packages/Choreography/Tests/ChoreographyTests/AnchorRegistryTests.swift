import Testing
import SwiftUI
@testable import Choreography

@Suite("ChoreographyState")
struct ChoreographyStateTests {

    /// `ChoreographyStateKey.reduce` must:
    ///   - merge anchors with last-write-wins (developer-error tiebreaker),
    ///   - append requests (each RedString call site is distinct).
    @Test("Reduce appends requests across siblings")
    func reduceAppendsRequests() {
        var value = ChoreographyStateKey.defaultValue
        #expect(value.requests.isEmpty)

        let r1 = RedStringRequest(
            id: "a→b",
            from: "a",
            to: "b",
            sag: 8,
            delay: .zero,
            duration: ChoreographyTiming.redString
        )
        let r2 = RedStringRequest(
            id: "b→c",
            from: "b",
            to: "c",
            sag: 4,
            delay: .milliseconds(80),
            duration: ChoreographyTiming.redString
        )

        ChoreographyStateKey.reduce(value: &value) {
            ChoreographyState(anchors: [:], requests: [r1])
        }
        ChoreographyStateKey.reduce(value: &value) {
            ChoreographyState(anchors: [:], requests: [r2])
        }

        #expect(value.requests.count == 2)
        #expect(value.requests[0].id == "a→b")
        #expect(value.requests[1].id == "b→c")
    }

    /// `RedStringRequest` id encodes the from/to pair so collisions across
    /// siblings are obvious in debug output.
    @Test("RedStringRequest id is from→to")
    func requestIdShape() {
        let req = RedStringRequest(
            id: "reuters→ap",
            from: "reuters",
            to: "ap",
            sag: 8,
            delay: .zero,
            duration: .milliseconds(920)
        )
        #expect(req.id == "reuters→ap")
        #expect(req.from == "reuters")
        #expect(req.to == "ap")
    }

    /// `RedStringRequest` is `Equatable` so the bundled preference value can
    /// short-circuit when nothing changed.
    @Test("RedStringRequest is Equatable")
    func requestEquatable() {
        let a = RedStringRequest(id: "x→y", from: "x", to: "y", sag: 8, delay: .zero, duration: .milliseconds(920))
        let b = RedStringRequest(id: "x→y", from: "x", to: "y", sag: 8, delay: .zero, duration: .milliseconds(920))
        let c = RedStringRequest(id: "x→z", from: "x", to: "z", sag: 8, delay: .zero, duration: .milliseconds(920))
        let d = RedStringRequest(id: "x→y", from: "x", to: "y", sag: 8, delay: .milliseconds(80), duration: .milliseconds(920))
        #expect(a == b)
        #expect(a != c)
        #expect(a != d)  // delay is part of identity for re-emit equality
    }

    /// Default `ChoreographyState` is fully empty.
    @Test("ChoreographyStateKey default has empty halves")
    func defaultIsEmpty() {
        let value = ChoreographyStateKey.defaultValue
        #expect(value.anchors.isEmpty)
        #expect(value.requests.isEmpty)
    }

    /// Reduce on empty inputs is a no-op (smoke test that the merge of empty
    /// maps and concat of empty lists doesn't crash).
    @Test("Reduce on empty inputs leaves state empty")
    func reduceEmpty() {
        var value = ChoreographyStateKey.defaultValue
        ChoreographyStateKey.reduce(value: &value) {
            ChoreographyState(anchors: [:], requests: [])
        }
        #expect(value.anchors.isEmpty)
        #expect(value.requests.isEmpty)
    }
}
