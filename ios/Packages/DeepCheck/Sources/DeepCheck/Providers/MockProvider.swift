// MARK: - MockProvider
//
// Hardcoded investigations keyed off the briefing's stable headline IDs
// (`mock-headline-0` through `-9`). Each investigation carries 5 sources
// with ~20-word wire-service-register excerpts and 5 pulled quotes with
// mono attribution.
//
// Per the 2026-05-03 deep-check brief §8: verdict distribution is
// 4 CONFIRMED / 3 BUSTED / 3 COLD CASE so all three stamp variants are
// exercised across the 10 cases. The 3 verdicts already pre-stamped in the
// DailyBriefing mock (FDA confirmed, Antarctic confirmed, City council
// busted) match the corresponding investigations here.
//
// All `publishedOn` dates are anchored to a fixed reference week so the
// mono date in the source caption ("MAY 02 2026") reads stably during
// screenshot review without depending on Date.now.

import Foundation
import Models

public struct MockProvider: DeepCheckProvider {

    public init() {}

    public func investigation(for kase: Case) async throws -> Investigation {
        guard let inv = Self.canned[kase.caseID] else {
            throw DeepCheckProviderError.unknownCase(kase.caseID)
        }
        // Re-bind the stored case with the live one (which carries the
        // briefing's caseNumber for today). Sources and evidence are stable.
        return Investigation(
            kase: kase,
            sources: inv.sources,
            evidence: inv.evidence,
            verdict: inv.verdict
        )
    }

    /// Number of canned investigations in which the given outlet appears as
    /// a source. Used by `SourceDossierSheet` for the
    /// "APPEARS IN N OF 10 ACTIVE CASES." caption.
    ///
    /// Static + synchronous because the canned table is process-local; when
    /// a real provider replaces this, the live shape will need to be async
    /// and the sheet will hold a small Task. Kept on the type so callers
    /// don't need a provider instance for the lookup.
    public static func outletAppearanceCount(_ outlet: String) -> Int {
        canned.values.reduce(into: 0) { count, inv in
            if inv.sources.contains(where: { $0.outlet == outlet }) {
                count += 1
            }
        }
    }

    /// Total number of canned cases — denominator for the appearance caption.
    public static var caseCount: Int { canned.count }

    // MARK: - Canned investigations

    private static let canned: [String: Investigation] = {
        [
            // 0 · Senate AI export-control deadlock — COLD CASE.
            "mock-headline-0": Self.investigation(
                caseID: "mock-headline-0",
                sources: [
                    ("Reuters", "Senate Foreign Relations panel adjourned its third hearing on the AI export-control package without a vote, citing unresolved disputes over chip-tier definitions.", refDate(month: 5, day: 2)),
                    ("AP", "A Senate panel adjourned a third closed-door session Thursday without scheduling a vote; the chair acknowledged gaps that have not closed.", refDate(month: 5, day: 2)),
                    ("BBC", "Senators failed for a third time to advance the draft bill, disagreeing on whether emerging-market datacenter buyers fall inside or outside the controls.", refDate(month: 5, day: 2)),
                    ("NPR", "Lawmakers exited the closed session without comment; staff confirmed a fourth meeting is being scheduled but offered no date.", refDate(month: 5, day: 2)),
                    ("Politico", "An aide said the chair is reluctant to bring the bill forward without firmer Republican commitments, and is circulating a redrafted definitions section.", refDate(month: 5, day: 2)),
                ],
                quotes: [
                    ("\"Gaps that have not closed.\" — committee chair, at adjournment.", "AP, May 2 2026"),
                    ("Disagreement focused on whether emerging-market datacenter buyers fall inside or outside the controls.", "BBC, May 2 2026"),
                    ("Third hearing, no vote; fourth meeting being scheduled.", "NPR, May 2 2026"),
                    ("Chair reluctant to bring forward without firmer Republican commitments.", "Politico, May 2 2026"),
                    ("Unresolved disputes over chip-tier definitions persist between members.", "Reuters, May 2 2026"),
                ],
                verdict: .coldCase
            ),

            // 1 · FDA insulin pump recall — CONFIRMED. Pre-stamped in briefing.
            "mock-headline-1": Self.investigation(
                caseID: "mock-headline-1",
                sources: [
                    ("Reuters", "FDA issued a Class I recall covering three insulin pump models after firmware reviews uncovered a delivery-rate fault that under-doses long-acting bolus profiles.", refDate(month: 5, day: 1)),
                    ("AP", "The agency confirmed the recall affects roughly 41,000 devices distributed in 2024 and 2025, with the manufacturer issuing a free firmware patch.", refDate(month: 5, day: 1)),
                    ("BBC", "FDA's Class I designation indicates a 'reasonable probability' the firmware fault could cause serious adverse events, including hospitalisation.", refDate(month: 5, day: 1)),
                    ("NPR", "Patients are advised to contact their endocrinologist; the manufacturer has set up a 24-hour support line and a firmware update portal.", refDate(month: 5, day: 1)),
                    ("STAT", "Three peer-reviewed adverse-event reports preceded the recall by six weeks; FDA acknowledges the lag and has opened a separate review.", refDate(month: 5, day: 1)),
                ],
                quotes: [
                    ("Class I recall — \"reasonable probability\" of serious adverse events.", "BBC, May 1 2026"),
                    ("Firmware delivery-rate fault under-dosing long-acting bolus profiles.", "Reuters, May 1 2026"),
                    ("Roughly 41,000 devices affected, distributed 2024–2025.", "AP, May 1 2026"),
                    ("Three peer-reviewed adverse-event reports preceded the recall by six weeks.", "STAT, May 1 2026"),
                    ("Free firmware patch and 24-hour support line stood up by manufacturer.", "NPR, May 1 2026"),
                ],
                verdict: .confirmed
            ),

            // 2 · Cargo ship grounded SF Bay — CONFIRMED.
            "mock-headline-2": Self.investigation(
                caseID: "mock-headline-2",
                sources: [
                    ("Reuters", "A 240-metre Panamanian-flagged cargo vessel grounded on a sandbar near Treasure Island during a strong morning ebb tide; no leakage reported.", refDate(month: 5, day: 3)),
                    ("AP", "USCG Sector San Francisco confirmed the ship is upright with structural integrity intact; salvage crews are staging tugs at Pier 70.", refDate(month: 5, day: 3)),
                    ("BBC", "Bay traffic was rerouted for six hours; the Port of Oakland reported no significant operational impact for container terminals.", refDate(month: 5, day: 3)),
                    ("KQED", "The ship's pilot, a 28-year veteran, was below recommended bridge staffing per a preliminary union account; NTSB is en route.", refDate(month: 5, day: 3)),
                    ("Marine Log", "Industry trackers note the vessel was three days into a transpacific charter and may have to lighter cargo before being refloated.", refDate(month: 5, day: 3)),
                ],
                quotes: [
                    ("USCG: ship upright, structural integrity intact, no leakage.", "AP, May 3 2026"),
                    ("Salvage tugs staging at Pier 70.", "AP, May 3 2026"),
                    ("Pilot below recommended bridge staffing per preliminary union account.", "KQED, May 3 2026"),
                    ("Vessel three days into transpacific charter; may have to lighter cargo.", "Marine Log, May 3 2026"),
                    ("Bay traffic rerouted six hours; no significant Port of Oakland impact.", "BBC, May 3 2026"),
                ],
                verdict: .confirmed
            ),

            // 3 · Mars program cuts in House appropriations — BUSTED.
            "mock-headline-3": Self.investigation(
                caseID: "mock-headline-3",
                sources: [
                    ("Reuters", "House appropriators advanced a CJS draft that nominally trims two Mars-related lines, though staff confirm the cuts are placeholder pending Senate counter-offer.", refDate(month: 5, day: 1)),
                    ("AP", "An advocacy group's press release calling the cuts 'devastating' was widely re-reported despite committee staff describing the figures as routine markers.", refDate(month: 5, day: 1)),
                    ("BBC", "The committee chair's published statement does not characterise the lines as cuts and references 'standard pre-conference adjustments.'", refDate(month: 5, day: 1)),
                    ("Space News", "Trade-press reporting flagged the discrepancy: the popular framing leans on the advocacy press release, not the markup text.", refDate(month: 5, day: 1)),
                    ("Ars Technica", "A side-by-side of the markup and the FY2025 enacted shows the affected lines are within the typical year-over-year noise band.", refDate(month: 5, day: 1)),
                ],
                quotes: [
                    ("Committee staff describe the figures as routine pre-conference markers.", "Reuters, May 1 2026"),
                    ("Chair's statement: \"standard pre-conference adjustments,\" not cuts.", "BBC, May 1 2026"),
                    ("Popular framing leans on the advocacy press release, not the markup text.", "Space News, May 1 2026"),
                    ("Affected lines within typical year-over-year noise band.", "Ars Technica, May 1 2026"),
                    ("Advocacy 'devastating' framing widely re-reported without qualification.", "AP, May 1 2026"),
                ],
                verdict: .busted
            ),

            // 4 · Antarctic calving — CONFIRMED. Pre-stamped in briefing.
            "mock-headline-4": Self.investigation(
                caseID: "mock-headline-4",
                sources: [
                    ("Reuters", "British Antarctic Survey confirms a 1,200-square-kilometre tabular berg detached from the Brunt Ice Shelf during the early hours of May 1.", refDate(month: 5, day: 1)),
                    ("AP", "Sentinel-1 radar imagery captured the calving event; the rift had been monitored since 2012 and had been advancing 4–5 km per year.", refDate(month: 5, day: 1)),
                    ("BBC", "BAS scientists describe the calving as 'overdue' and consistent with long-term shelf dynamics, not as an acute climate-attribution event.", refDate(month: 5, day: 1)),
                    ("NASA Earth Observatory", "MODIS visible imagery from May 2 shows the iceberg drifting north-northeast under the Weddell Gyre's prevailing flow.", refDate(month: 5, day: 2)),
                    ("Nature News", "Glaciologists caution that calving size alone is not a climate signal; the loss is within historical range for this shelf.", refDate(month: 5, day: 2)),
                ],
                quotes: [
                    ("BAS: 1,200 sq-km tabular berg detached from Brunt during early hours of May 1.", "Reuters, May 1 2026"),
                    ("BAS scientists: calving is \"overdue,\" consistent with long-term shelf dynamics.", "BBC, May 1 2026"),
                    ("Rift monitored since 2012, advancing 4–5 km per year.", "AP, May 1 2026"),
                    ("Glaciologists: calving size alone is not a climate signal.", "Nature News, May 2 2026"),
                    ("Berg drifting north-northeast under Weddell Gyre flow.", "NASA Earth Observatory, May 2 2026"),
                ],
                verdict: .confirmed
            ),

            // 5 · BoJ holds rates — BUSTED (framing).
            "mock-headline-5": Self.investigation(
                caseID: "mock-headline-5",
                sources: [
                    ("Reuters", "Bank of Japan held its short-term policy rate at 0.50% as expected; the official statement contains no language committing to no-shift through summer.", refDate(month: 5, day: 1)),
                    ("AP", "Governor declined to rule out a summer move when pressed in the press conference, saying decisions remain 'data-dependent meeting by meeting.'", refDate(month: 5, day: 1)),
                    ("BBC", "Wire-service framing of 'no shift through summer' originated with one analyst note, not with the bank's own communication.", refDate(month: 5, day: 1)),
                    ("Bloomberg", "Swap markets reprised modestly hawkish after the press conference, suggesting traders did not interpret the statement as a hold-through-summer.", refDate(month: 5, day: 1)),
                    ("Nikkei", "Japanese-language coverage emphasised the data-dependency caveat that English-language wire reports under-weighted.", refDate(month: 5, day: 1)),
                ],
                quotes: [
                    ("BoJ: rate held 0.50%; no language committing to no-shift through summer.", "Reuters, May 1 2026"),
                    ("Governor: \"data-dependent meeting by meeting.\"", "AP, May 1 2026"),
                    ("'No shift through summer' framing originated with an analyst note, not the bank.", "BBC, May 1 2026"),
                    ("Swap markets reprised modestly hawkish — not a hold-through-summer read.", "Bloomberg, May 1 2026"),
                    ("Japanese-language coverage emphasised the data-dependency caveat.", "Nikkei, May 1 2026"),
                ],
                verdict: .busted
            ),

            // 6 · DNS provider outage — CONFIRMED.
            "mock-headline-6": Self.investigation(
                caseID: "mock-headline-6",
                sources: [
                    ("Reuters", "A major managed-DNS provider experienced a 92-minute control-plane incident that propagated stale records to roughly 18% of resolvers globally.", refDate(month: 5, day: 2)),
                    ("AP", "The outage affected three large US retail-banking apps relying on the provider for authoritative answers; consumer login was the dominant failure mode.", refDate(month: 5, day: 2)),
                    ("BBC", "The provider's published post-mortem attributes the incident to a config-deploy misroute that affected anycast withdrawal scheduling.", refDate(month: 5, day: 3)),
                    ("The Register", "Independent vantage points from public RIPE Atlas probes confirmed the timeline: stale answers from 14:08 UTC, recovery by 15:40 UTC.", refDate(month: 5, day: 2)),
                    ("Krebs on Security", "No evidence of malicious activity; the provider published anonymised tcpdump excerpts from one affected pop within 12 hours of recovery.", refDate(month: 5, day: 3)),
                ],
                quotes: [
                    ("92-minute control-plane incident, ~18% of global resolvers affected.", "Reuters, May 2 2026"),
                    ("Three US retail-banking apps affected; consumer login was the dominant failure mode.", "AP, May 2 2026"),
                    ("Cause: config-deploy misroute affecting anycast withdrawal scheduling.", "BBC, May 3 2026"),
                    ("RIPE Atlas vantage points confirm 14:08 UTC stale answers, recovery 15:40 UTC.", "The Register, May 2 2026"),
                    ("No malicious activity; tcpdump excerpts published within 12 hours.", "Krebs on Security, May 3 2026"),
                ],
                verdict: .confirmed
            ),

            // 7 · City council riverfront — BUSTED. Pre-stamped in briefing.
            "mock-headline-7": Self.investigation(
                caseID: "mock-headline-7",
                sources: [
                    ("Reuters", "City council voted 6-3 against a developer's redevelopment proposal for a riverfront industrial parcel; vote breakdown is in the public record.", refDate(month: 4, day: 30)),
                    ("AP", "The 6-3 framing in regional wire reports collapses two procedural votes into one; the substantive land-use vote was 5-3 with one abstention.", refDate(month: 4, day: 30)),
                    ("BBC", "Local TV coverage led with 'rejected outright,' but the council resolution explicitly invites a revised proposal under updated zoning guidance.", refDate(month: 4, day: 30)),
                    ("Local Tribune", "The outright-rejection framing missed the resolution language; the developer issued a Friday statement signalling intent to revise.", refDate(month: 5, day: 1)),
                    ("KQED", "Two council members on the prevailing side described the outcome as 'a redirect, not a no,' a quote absent from regional wire coverage.", refDate(month: 5, day: 1)),
                ],
                quotes: [
                    ("Two procedural votes were collapsed into one in the '6-3' framing.", "AP, April 30 2026"),
                    ("Substantive land-use vote was 5-3 with one abstention, not 6-3 outright.", "AP, April 30 2026"),
                    ("Council resolution explicitly invites a revised proposal under updated zoning.", "BBC, April 30 2026"),
                    ("Council members: \"a redirect, not a no.\"", "KQED, May 1 2026"),
                    ("Outright-rejection framing missed the resolution language.", "Local Tribune, May 1 2026"),
                ],
                verdict: .busted
            ),

            // 8 · Auto union ratifies — CONFIRMED → COLD CASE per brief mix.
            "mock-headline-8": Self.investigation(
                caseID: "mock-headline-8",
                sources: [
                    ("Reuters", "Local 600 ratified the tentative agreement by a 71% margin; the international has not yet certified the final ballot count.", refDate(month: 5, day: 1)),
                    ("AP", "Two adjacent locals at the same plant continue to count ballots; reports of a plant-wide ratification are premature ahead of the certification.", refDate(month: 5, day: 1)),
                    ("BBC", "Industry observers note the three-shift assembly framing assumes a configuration that has not yet been confirmed in the agreement language.", refDate(month: 5, day: 1)),
                    ("Detroit Free Press", "The final certification typically takes 5–10 business days; the union's press office confirms the timeline is on the longer end this round.", refDate(month: 5, day: 2)),
                    ("Labor Notes", "Dissenting members at one local have filed two procedural objections that, if upheld, could affect the final ratification certification.", refDate(month: 5, day: 2)),
                ],
                quotes: [
                    ("Local 600 ratified by 71%; international has not yet certified final count.", "Reuters, May 1 2026"),
                    ("Two adjacent locals continue counting; plant-wide ratification reports are premature.", "AP, May 1 2026"),
                    ("Three-shift assembly framing assumes a configuration not yet confirmed in language.", "BBC, May 1 2026"),
                    ("Final certification 5–10 business days; press office confirms longer end this round.", "Detroit Free Press, May 2 2026"),
                    ("Two procedural objections filed at one local; could affect certification.", "Labor Notes, May 2 2026"),
                ],
                verdict: .coldCase
            ),

            // 9 · Battery cycle-life lab claim — COLD CASE.
            "mock-headline-9": Self.investigation(
                caseID: "mock-headline-9",
                sources: [
                    ("Reuters", "A research-group preprint reports a doubled cycle-life under controlled lab conditions for a sulfide-based solid-state cell, awaiting peer review.", refDate(month: 4, day: 28)),
                    ("AP", "Wire summaries of 'doubled cycle life' omit the cell-format caveat: the result applies to a 50 mAh coin-cell, not commercially relevant pouch formats.", refDate(month: 4, day: 28)),
                    ("BBC", "Two independent battery scientists declined to comment on record pending peer review; one called the claim 'plausible but unverified.'", refDate(month: 4, day: 28)),
                    ("IEEE Spectrum", "Trade-press analysis flagged that cycle-count protocols vary widely and that doubling under one protocol may not transfer to industry-standard.", refDate(month: 4, day: 28)),
                    ("Ars Technica", "The lab confirmed they have no commercial partner and no path to scaled fabrication; cycle-life claim is at lab-bench scale.", refDate(month: 4, day: 28)),
                ],
                quotes: [
                    ("Result applies to 50 mAh coin-cell, not commercially relevant pouch formats.", "AP, April 28 2026"),
                    ("Independent scientists: \"plausible but unverified,\" declining on-record comment pre-peer-review.", "BBC, April 28 2026"),
                    ("Cycle-count protocols vary widely; doubling may not transfer to industry-standard.", "IEEE Spectrum, April 28 2026"),
                    ("Lab confirms no commercial partner, no scaled-fabrication path.", "Ars Technica, April 28 2026"),
                    ("Sulfide-based solid-state cell, controlled lab conditions, preprint awaiting peer review.", "Reuters, April 28 2026"),
                ],
                verdict: .coldCase
            ),
        ]
    }()

    // MARK: - Builders

    private static func investigation(
        caseID: String,
        sources: [(String, String, Date)],
        quotes: [(String, String)],
        verdict: Case.Verdict
    ) -> Investigation {
        let mappedSources = sources.enumerated().map { index, triple in
            Source(
                id: "\(caseID)-source-\(index)",
                outlet: triple.0,
                excerpt: triple.1,
                publishedOn: triple.2
            )
        }
        let mappedEvidence = quotes.enumerated().map { index, pair in
            EvidenceQuote(
                id: "\(caseID)-quote-\(index)",
                quote: pair.0,
                attribution: pair.1
            )
        }
        // Stub case — `investigation(for:)` re-binds to the live Case before
        // returning, so these placeholder fields never reach the screen.
        let stubCase = Case(
            caseID: caseID,
            caseNumber: "CASE-26-XXXX-XXX",
            headline: "(canned-stub)",
            verdict: verdict
        )
        return Investigation(
            kase: stubCase,
            sources: mappedSources,
            evidence: mappedEvidence,
            verdict: verdict
        )
    }

    private static func refDate(month: Int, day: Int) -> Date {
        var comps = DateComponents()
        comps.year = 2026
        comps.month = month
        comps.day = day
        return Calendar(identifier: .gregorian).date(from: comps) ?? Date()
    }
}
