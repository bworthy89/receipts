# Product

## Register

product

## Users

People who scroll social — TikTok, YouTube Shorts, X, group chats — and hit a "wait, is that even real?" moment several times a day. They're not journalists, not fact-checkers, not subscribed to Snopes. They're regulars who are tired of getting played by viral-bullshit videos and want a fast way to call it out (or get called out) without becoming a full-time researcher.

Their context is **mid-scroll, on iPhone**, often inside iMessage or a group thread. The job-to-be-done is: **paste a link, get a screenshottable verdict, share or move on.** Closing the loop matters as much as the verdict — most uses end with the artifact landing in a group chat, not with the user reading a long fact-check.

They have a phone in one hand and probably 30 seconds. The product treats their attention like that.

## Product Purpose

For Real?? is a single-purpose iOS utility. Paste a TikTok, YouTube, or article URL; the app analyzes it and streams back **a fax** — a final verdict (`nope` / `mixed` / `yep` / `skip`) plus 2–3 individual claim cards, each with its own per-claim verdict and a one-liner of sassy commentary in the app's voice.

The fax is the product. Every screen exists to produce one or to recall one. There is no feed, no daily briefing, no "open the app to browse." Open, paste, watch the fax fill in claim-by-claim over ~20–60 seconds, screenshot, share, close.

**Hero feature: the streaming fax.** Claims arrive one at a time as the backend resolves them — visible proof-of-work. The user watches the AI think. Spinners are a defeat.

**The bestie tone is the differentiator.** Snopes can tell you a study doesn't exist. For Real?? sends *"Bestie. The 'Harvard study' he keeps citing? Doesn't exist. Made it up. Truly bold of him."* Same correctness, different audience.

**Naming note.** Users get *a fax* — *"send me the fax on this video,"* *"got the fax,"* *"what's the fax say?"* The wordplay is on "fact / facts / fax." The codebase still uses `receipts` everywhere — DB tables, API paths, the analyzer worker name — because renaming infrastructure earns no user-visible value. **Engineering namespace** stays `crimeboard` for the same reason. Three layers, three audiences, no collapse.

**Success at one month**: when a user encounters a viral claim and reaches for For Real?? before reaching for Google, before asking their group chat, before assuming. The app earns its place because the fax is the thing they want to share — the format is the marketing.

## Brand Personality

**Sassy, sharp, screenshot-bait.**

- **Sassy** — the bestie venom. Talking back, not lecturing. *"Bestie, this 'study' is not real. Made up. Fake. Imaginary."* The voice is a smart friend roasting a TikTok, not an institutional referee handing down a verdict.
- **Sharp** — smart, cutting, never soft. The humor lands because the analysis is genuinely correct. The fax is *funnier* when it's right; if the verdict is wrong, the joke deflates. Accuracy carries the comedy.
- **Screenshot-bait** — every fax is designed to live as a 1080×1920 image dropped in someone's group chat. Visually punchy, type-forward, scannable in three seconds, no mystery-meat icons. The format is the marketing.

The voice never punches at the user. It punches at the claim, the source, the bullshit. The user is the smart friend the app is talking *to*, not the target.

There are no streaks, no XP bars, no badges, no level-ups. There is also no app-tutorial mascot, no onboarding video, no "here's how it works" carousel. The fax explains itself the first time you see one.

## Anti-references

If a screen could be lifted from any of these and dropped into For Real?? without a designer noticing, we have failed.

- **"Obvious AI design"** — the canonical AI-startup aesthetic: cream-and-sage palettes, ✨ sparkle icons, frosted-glass cards, "AI-native" SaaS marketing. The single most-direct visual anti — if a fax could be guessed as "made by an AI app" before reading a word of copy, the design has failed.
- **ChatGPT / Claude / generic AI chat window** — chat-bubble UI as the whole interface. Looks like a thousand other LLM wrappers. The fax is not a conversation; it's an artifact.
- **Snopes / PolitiFact** — institutional fact-check sites. Dry, earnest, "we are the truth referee" tone. Editorially correct but exactly the energy we're escaping. The user already knows Snopes exists; they're not using it. We're not a Snopes wrapper.
- **Threads / news-Twitter** — feed-y, scrollable, too much UI, not single-purpose. The home screen is a paste box, not a timeline.
- **Apple News / NYT / WaPo apps** — broadsheet reverence, serif solemnity, publisher logo as authority. The opposite of bestie tone. We're not deferring to anyone, including ourselves.
- **Duolingo / LinkedIn** — gamification compulsion loops, streak panic, badge menus, "you've earned a trophy!" celebrations. For Real??'s satisfaction is the fax landing in a group chat, not points accumulating.
- **Linear / Notion / generic dark-mode productivity SaaS** — over-designed tool aesthetic. Sleek-but-faceless. We're a utility, not a tool. The brand has personality; productivity SaaS doesn't.

The shared failure across all of these is **flattening into a category**. If For Real?? can be guessed from the category alone — "fact-check app" → dry institutional, or "AI utility" → cream-and-sage SaaS — the design has lost.

## Design Principles

1. **Single-purpose utility, not destination.** No feed, no daily briefing, no "open to browse." Paste in → fax out → close. Every screen serves the paste-or-revisit loop. Rejects the muscle of "open the app and see what's new."

2. **The fax is the artifact.** It's built to be screenshotted into iMessage. The output, not the input, carries the brand. If the fax looks bad as a 1080×1920 image dropped in a group chat, the design has failed — even if the analysis is correct.

3. **Bestie, not referee.** Sassy and sharp; never institutional. The smart friend roasting a TikTok, not a fact-check site explaining the truth. Humor keeps the user company through their skepticism — and never punches at the user.

4. **Show the work without making them wait.** Streaming claims one at a time is proof-of-work, not loading polish. The user *watches* the AI think. Spinners and skeletons are a defeat — if you have to show one, the streaming order is wrong.

5. **Format-aware honesty.** When a video isn't checkable (opinion, joke, music, all-vibes), the fax says so plainly in the same voice — `skip` is a verdict, not a failure. The app never invents a verdict to look authoritative; the bestie tone falls flat the moment the analysis is wrong.

## Accessibility & Inclusion

**WCAG 2.2 AA** baseline across the entire app, with a **first-class Reduce Motion path** for the streaming fax.

- **Reduce Motion** — the streaming claim-by-claim fill is the hero motion. With Reduce Motion on, claims still appear in order, but as instant placements with a brief highlight rather than animated entries. The information sequence (status → claim 1 → claim 2 → claim 3 → final verdict) is preserved; the theatrical motion is replaced with content reveals. Reduce Motion users still get the proof-of-work feel — they just get it without vestibular cost.
- **VoiceOver** — labels written in the app's voice, never as raw data. *"Fax for TikTok video. Verdict: nope. Three claims checked, one nope, one mixed, one yep. Bestie commentary follows..."* Verdict changes, claim arrivals, and final synthesis are spoken changes, not silent visual ones.
- **Color & contrast** — the drenched-yellow surface is a known thumbnail-compression risk. Verdict glyphs (❌ 🤷 ✅ 🤔) are paired with text labels and structural placement; verdict identity never relies on color alone. The fax must remain legible at thumbnail size inside iMessage previews and Instagram screenshots.
- **Type & touch** — Dynamic Type honored throughout, including inside the fax card. Touch targets meet 44pt minimum. The paste-from-clipboard affordance must remain reachable with one thumb.
- **Sound** — every audio cue is a *secondary* channel; no information is sound-only. A muted device loses flavor, never function.

The bar is: a screen-reader user, a Reduce Motion user, and a sighted user with motion enabled all describe the same fax — same verdict, same claims, same bestie tone — at the end of the same paste.
