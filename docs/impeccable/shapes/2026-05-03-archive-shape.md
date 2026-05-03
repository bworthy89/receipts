# Archive — Design Brief

**Date:** 2026-05-03
**Command:** `$impeccable craft archive`
**Status:** Confirmed by user 2026-05-03
**Skill applicability:** The `impeccable` skill **applies** to the implementation plan.

---

## 1. Feature Summary

A scannable shelf of past cases the user has Deep-Checked. Each case renders as a sepia-toned polaroid card with case number, headline, verdict stamp, and investigated date. Cards are grouped by day with quiet mono headers. Reached from a "ARCHIVE · N FILED" footer at the bottom of the briefing's cork board; tap a polaroid to re-read its Deep Check.

## 2. Primary User Action

**Scan the procedural record of work done.** Cards are skimmable; the verdict stamp tells you the outcome at a glance; tap to re-read.

## 3. Design Direction

- **Color strategy:** **Restrained.** Cork Tan substrate. Sepia for the polaroid borders (the time-depth cue per DESIGN.md's named role). Paper White face on each polaroid. Ink Black serif headlines. Evidence Red appears only via the verdict stamps already baked into investigated cases — same Red-String Rule as Deep Check, no new red.
- **Scene sentence:** *"Same reader, weeks in — coming back to look at what they've actually checked. The desk lamp is the same; the cases on top are fresh, the ones at the bottom of the stack have started to yellow."* Light primary, Dim Room dark honored.
- **Named anchors:** real polaroid stacks on a desk, a detective's cleared-cases drawer, late-archive newspaper morgue file boxes.

## 4. Scope

Production-ready single screen. New SPM package `Archive` consuming `Models` + `DesignSystem` + `DeepCheck`. Includes:

- `ArchiveScreen` — cork-substrate vertical scroll of polaroid cards, day-grouped.
- `ArchivePolaroid` — sepia-bordered polaroid card with case number, serif headline, verdict stamp, investigated-on caption.
- **`InvestigationLog` schema upgrade** — currently stores a JSON-encoded `[String]` of caseIDs. Change to `[caseID: ArchiveEntry]` where `ArchiveEntry` carries `(caseNumber, headline, verdict, investigatedOn)`. Snapshot at investigation-time so the archive is self-sufficient — doesn't need a provider hop to render. Old format fails open to empty (same pattern as PR #7's JSON change).
- `DailyBriefingScreen` gets an "ARCHIVE · N FILED" footer at the bottom of the cork board; tap presents `ArchiveScreen` via `fullScreenCover`.
- `ArchiveScreen` presents the existing `DeepCheckScreen` via `fullScreenCover` for re-reads. Skip-on-revisit logic in `DeepCheckScreen` already renders `SettledBoard` for any case in the log.
- Mock data: pre-populate `InvestigationLog` at first launch (DEBUG only) with 4–5 of the 10 mock cases on staggered dates, so the archive demos as non-empty across multiple day groups.

## 5. Layout Strategy

- **Cork-board substrate.** Same `CorkBoard` primitive as briefing.
- **Vertical scroll**, single column of polaroid cards, centered.
- **Day group headers** — mono uppercase, hairline divider beneath: `"TODAY · MAY 03 · 3 CASES"`, `"YESTERDAY · MAY 02 · 5 CASES"`, `"MAY 01 · 2 CASES"`. Spaced with `Spacing.section` between groups.
- **Polaroid cards** — sepia border, paper-white face, ±2° per-card rotation (seeded RNG by caseID for stable position), `polaroidShadow` from DesignSystem.
- **Card content layout (top → bottom):**
  - Mono case-number top-right inside the polaroid border.
  - Serif headline on the paper-white face (3-line clamp, 17pt body).
  - Verdict stamp slammed across the lower portion of the headline, ~-7° rotation (matches Source Dossier + briefing convention).
  - Sepia bottom border with mono "INVESTIGATED · MAY 02 2026" caption.
- **Custom × CLOSE affordance** at the top-left, same shape as Deep Check's.
- **Empty state** if log is empty: centered torn note "*Nothing on file. Quiet beat.*"

## 6. Key States

- **Default — populated.** Polaroids stack vertically by day. Tap any card → fullScreenCover with Deep Check (settled).
- **Empty.** Single centered torn note with the empty-state copy.
- **Single-day-only.** No group header if only one day's worth of cases (the sole group reads as the header itself, e.g., "TODAY").

## 7. Interaction Model

- **Entry:** tap "ARCHIVE · N FILED" footer on the briefing → fullScreenCover presents `ArchiveScreen`.
- **Dismiss:** tap × CLOSE in the top-left, OR iOS-default sheet drag from anywhere.
- **Re-read:** tap a polaroid → fullScreenCover presents `DeepCheckScreen(case:)`. Skip-to-settled fires automatically. Closing returns to Archive (not all the way back to Briefing).
- **Long-press:** no-op in v1 (deferred — could later trigger "remove from archive" or "share" affordances).

## 8. Content Requirements

- **Footer copy on briefing:** `"ARCHIVE · N FILED"` (uppercase mono, where N = size of investigated set).
- **Group header copy:** `"TODAY · MAY 03 · 3 CASES"` for today; `"YESTERDAY · MAY 02 · 5 CASES"` for prior; absolute date for older (`"MAY 01 · 2 CASES"`).
- **Card caption:** `"INVESTIGATED · MAY 02 2026"` mono, in the polaroid's bottom border.
- **Empty state:** `"Nothing on file. Quiet beat."` (echoes the briefing's empty voice).
- **VoiceOver per card:** `"Archived case: [headline]. Verdict: [verdict]. Investigated [date]. Double-tap to re-read."`

## 9. Recommended References

- `reference/spatial-design.md` — vertical polaroid stack with day-group rhythm.
- `reference/typography.md` — serif headline + mono procedural metadata layered on a polaroid.
- `reference/interaction-design.md` — fullScreenCover-from-fullScreenCover (Briefing → Archive → Deep Check).

## 10. Open Questions (resolve during craft)

- **Day-group threshold for "TODAY" / "YESTERDAY" wording.** Use these labels for the 0/1-day-back groups; absolute date formatting for older. Lean: yes; clearer scan.
- **Sepia tint specifics.** `Color.sepia` already exists in DesignSystem; the polaroid border uses it as-is. If contrast becomes an issue at the bottom-caption strip, tune at craft.
- **Card width & rotation seed.** Width ~280pt, rotation seeded from caseID via `SeededRNG.seed(from:)` so position is stable across re-renders.
- **InvestigationLog migration story.** Old format (JSON `[String]`) should fail open to empty rather than crash — same fail-open pattern shipped in PR #7.
- **DEBUG-only mock seed.** Pre-populate the log with N cases for screenshot review. Decide N = 4–5 across 2–3 days at craft time.
