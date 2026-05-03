# Product

## Register

product

## Users

News-skeptical adults — readers who have been burned by algorithmic feeds, distrust outlets across the spectrum, and want real transparency about where claims come from and how reliable a source is. Their context is daily, often on a phone, often quick (a morning briefing, a "wait, is this real?" moment mid-scroll). Their job-to-be-done is **verifying without becoming a full-time fact-checker** — they want the receipts a journalist would gather, surfaced inline, without having to leave the app or trust another aggregator's verdict.

The detective metaphor is empowerment, not entertainment. They are not here to be amused; they are here to feel sovereign over what they believe.

Primary surface is **iOS (SwiftUI)**. Native-first because the tactile, weighted interactions (pin-drops, red-string draws, polaroid develops, stamp slams) are core to the trust mechanic — they're the visible proof that the app is doing real work on the user's behalf.

## Product Purpose

THE CRIME BOARD reframes news consumption as **investigation rather than reception**. Every story arrives as a case on a cork board: source pins, evidence dossiers, connecting strings, reliability stamps. The hero feature is **Deep Check** — a visible, animated process where the app interrogates sources and draws connections between them in front of the reader. The user watches the work happen.

Adjacent features serve the same trust-building goal:

- **BiasMeter** — an evidence dossier collected per case, not a single number; readers see *what* informed the assessment.
- **Reading Diet** — case-clearance stats and outlet exposure, framed as detective-procedural rather than self-improvement gamification.
- **Streak / "Days on the beat"** — habit signal, but never the point.
- **Pro tier ("Senior Detective")** — extra investigative tools (cross-case linking, archive search, raw-source export) for power users.

**Success at one month**: the user reports they trust news again — meaning they feel they can spot bias and verify claims on their own, with or without the app. The app is teaching, not engaging. Daily-active is a leading indicator; *self-reported literacy* is the actual goal.

## Brand Personality

**Tactile, wry, sovereign.**

- **Tactile** — the cork board is the stage and it behaves like real material. Pins have weight and ricochet; polaroids develop; stamps slam with screen shake. Every interaction has friction, sound, and satisfaction. Nothing is weightless.
- **Wry** — voice is sharp, dry, self-aware. Stand-up comedian energy, not press-release. Empty state: *"Quiet day on the beat. Allegedly."* Verdict copy: *"Closed: B.S. confirmed."* Outlet labels: *"Persons of interest."* The humor never punches at the user — it keeps the user company through their skepticism.
- **Sovereign** — the app addresses the reader as a peer doing serious work, not a student to be educated or a feed-consumer to be entertained. Tone is confident without being reverent.

The "game" is the workflow itself. Every state change earns its motion. There are no XP bars, no level-up popups, no trophy rooms. Achievement lives as **case files in the archive** — narrative artifacts of what the user has actually done, not abstract scores.

## Anti-references

- **Duolingo** — XP bars, level-up celebrations, streak panic, mascot guilt. Gamification as compulsion loop. THE CRIME BOARD's satisfaction is *workflow weight*, not point accumulation.
- **LinkedIn** — badges menu, achievement-as-trophy, public-facing status games. Achievements here are private case files in the archive, not a wall of medals.
- **Apple News / Google News** — anonymous algorithmic feed, generic story cards, no point of view, publisher logo as authority. The opposite of an investigation; treats the reader as a passive endpoint.
- **NYT / WaPo apps** — broadsheet reverence, deference to publisher voice, serif solemnity. Editorially excellent, but exactly the institutional tone our wry copy refuses. Our reader does not need the news to be respectable; they need it to show its work.
- **Ground News / AllSides** — balance-as-bar-chart, library-of-sources visual language, civic-tech earnestness. Functional but lifeless. THE CRIME BOARD shares the goal of cross-source visibility, but renders it as physical evidence on a board, not a filterable dataset.

If a screen could be lifted from any of these and dropped into our app without a designer noticing, we have failed.

## Design Principles

1. **Show the work, not the verdict.** Trust is built by visibly checking sources in front of the reader (pin-and-string Deep Check, source cards flipping to reveal credibility), not by stamping a final true/false on a story. The mechanism is the message — when in doubt, expose more of the process, not the conclusion.

2. **The game is the workflow.** Every interaction earns its weight, sound, and satisfaction. No XP, no badges, no leveling popups. If a moment doesn't feel physically good — pin landing with ricochet, stamp slamming with screen shake, string drawing stroke-by-stroke — it isn't doing its job. Motion is meaning, not decoration.

3. **The reader is the detective.** Address the user as a peer doing serious work. Outlets are sources to be interrogated, not authorities to defer to. The interface never explains misinformation *to* the reader; it hands them the dossier and gets out of the way.

4. **Wry, never reverent.** Copy keeps the user company through their skepticism with stand-up timing — *"Quiet day on the beat. Allegedly."* — but never punches at the user, the story, or any one outlet. Sermons and lectures are the tone we are escaping; we don't reproduce them.

5. **Literacy is the product, engagement is the side effect.** Daily streaks and case-clearance stats exist, but they're framed as procedural artifacts ("days on the beat," "open cases"), never as the reason to come back. The win is the reader leaving the app *more capable*, not more hooked. Anything that optimizes for time-on-app at the cost of literacy is a feature we don't ship.

## Accessibility & Inclusion

**WCAG 2.2 AA** baseline across the entire app, with a **first-class Reduce Motion path** rather than a token fallback.

- **Reduce Motion** — every theatrical animation has a meaningful static or low-motion equivalent that preserves the *information* being conveyed. Pin-drops become instant placement with a subtle highlight; red-string draws become solid lines that fade in; polaroid develops become immediate image reveals; stamp slams become a labeled stamp graphic without screen shake. Reduce Motion users still get the detective experience — they just get it without vestibular cost.
- **VoiceOver** — labels written in the same detective vocabulary the visual UI uses, never as raw data. ("New source pinned: Reuters, high reliability, connects to two existing pins" rather than "Image, button, source 3 of 7.") Connections, verdicts, and case state are spoken changes, not silent visual ones.
- **Color & contrast** — all critical reliability/verdict signals carry shape, label, and position cues in addition to color. The cork-board palette is constructed with chroma-aware contrast so red string, push pins, and stamp inks remain distinguishable for the most common color-vision differences.
- **Type & touch** — Dynamic Type honored throughout, including inside polaroid captions and stamp text. Touch targets meet 44pt minimum even when visual elements (pins, photo corners) appear smaller.
- **Sound** — every audio cue (pin-drop thunk, stamp slam, string twang) is a *secondary* channel; no information is sound-only. A muted device loses flavor, never function.

The bar is: a screen-reader user, a Reduce Motion user, and a sighted user with motion enabled all describe the same case state in the same detective language at the end of the same Deep Check.
