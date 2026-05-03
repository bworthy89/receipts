// MARK: - Investigation
//
// The data Deep Check needs to render: the case under investigation, its
// five sources, the pulled quotes that became evidence, and the verdict.
//
// Per the 2026-05-03 brief §8 Content Requirements:
//   • 5 sources with ~25-word excerpts each
//   • 5 evidence quotes (not necessarily 1:1 mapping to sources — two sources
//     can echo the same framing)
//   • verdict drives the StampSlam at the end of the sequence
//
// Investigation does NOT include the back-references from quotes to sources,
// because the dossier renders quotes with attribution baked into the
// `EvidenceQuote.attribution` string. If the future Deep Check 2.0 wants
// "tap a quote → highlight the source", the link can land then.

import Foundation
import Models

public struct Investigation: Sendable, Equatable {
    public let kase: Case
    public let sources: [Source]
    public let evidence: [EvidenceQuote]
    public let verdict: Case.Verdict

    public init(
        kase: Case,
        sources: [Source],
        evidence: [EvidenceQuote],
        verdict: Case.Verdict
    ) {
        self.kase = kase
        self.sources = sources
        self.evidence = evidence
        self.verdict = verdict
    }
}

// MARK: - EvidenceQuote
//
// One row in the below-the-fold dossier. Serif quote + mono attribution.
// Per the brief: each row is "a serif quote with mono attribution
// ('— Reuters, May 3 2026')."

public struct EvidenceQuote: Sendable, Equatable, Identifiable {
    public let id: String
    public let quote: String
    public let attribution: String

    public init(id: String, quote: String, attribution: String) {
        self.id = id
        self.quote = quote
        self.attribution = attribution
    }
}
