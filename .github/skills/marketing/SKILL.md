---
name: marketing
description: "Establish or evolve a project's marketing identity in docs/marketing/MARKETING.md, and produce per-launch GTM plans. Use when the user asks for marketing work, when a feature requires marketing artifacts (landing page, sales-oriented copy), when MVP is complete and no MARKETING.md exists, or when an existing MARKETING.md needs to be updated. Runs an interview-style discovery, validates audience and positioning, locks decisions, and resists generic marketing AI-slop."
---

# Create Marketing

This skill guides the creation or iteration of the project's marketing identity, captured in `docs/marketing/MARKETING.md`, and the production of per-launch GTM plans under `docs/marketing/`. Marketing copy is the highest-risk surface for generic AI-slop and for unverified claims; this skill enforces structured discovery, voice/truth guardrails, and lock-as-you-decide iteration.

## When to use

- `docs/marketing/MARKETING.md` does not exist and the user asks for marketing work
- MVP is complete and no `MARKETING.md` exists yet (first-creation trigger)
- A feature requires marketing artifacts (landing page, sales contact form, sales-oriented website, launch announcement) and no `MARKETING.md` exists yet
- The user explicitly asks to establish or evolve marketing
- A specific launch / release / campaign is approaching and needs a GTM plan
- This skill is invoked for non-trivial promo content and finds `MARKETING.md` stale or absent

This skill engages mostly on-demand, with a few auto-triggers (inception lightweight pass, MVP completion, feature-mandated marketing artifacts). It does **not** run on every project change.

## Source of truth

`docs/marketing/MARKETING.md` is the durable contract: positioning, audience, messaging matrix, voice deltas from DESIGN.md, channels, content strategy. Per-engagement promo copy (landing copy, launch posts, social, blog drafts) lives in dated files at `docs/marketing/<yyyy-mm-dd>_<slug>.md` — **not** in `MARKETING.md`.

## Process

### 1. Pre-flight: read first, deduce, verify

Before asking the user anything, read:

- `DESIGN.md` — adopt its **Voice** section by default. Only diverge with explicit rationale and call out the delta in `MARKETING.md`.
- `docs/specs/roadmap.md` — the actual product roadmap. What's shipped vs. what's planned vs. what's deferred.
- Recent specs in `docs/specs/` — what features actually exist and behave how.
- `README.md` — implied audience, domain, tone.
- `docs/memory/decisions.md` — prior product/marketing decisions.
- The codebase itself — at minimum a top-level scan. **You must be able to verify any claim you'll make.** No marketing fiction.

From these, **deduce** an initial audience and positioning hypothesis. The interview validates the deduction; it does not start from zero.

### 2. Voice/positioning currency check (iteration only)

If `MARKETING.md` already exists, before doing the requested work:

- Compare the current voice section to `DESIGN.md`'s voice section. If `DESIGN.md` has changed materially, propose a voice refresh first.
- Compare the current positioning to the current `docs/specs/roadmap.md`. If the product has pivoted, propose a positioning refresh first.
- Get a quick OK from the user, apply the refresh, then proceed with the originally-requested work.

This is the **only** automatic sync moment. Outside of an invocation, `MARKETING.md` does not drift.

### 3. Validate audience and positioning hypothesis

Present your deduced audience and positioning to the user as a concrete proposal, not a question:

> Based on the roadmap and codebase, I think this is for: **[specific role] who currently does [specific task] with [specific alternative]**, and the positioning is: **[specific differentiator]**. Confirm, refine, or correct.

Push for **specifics**:
- Roles, not "developers". (Backend engineers at growth-stage SaaS? ML researchers? Indie hackers shipping side projects?)
- Concrete current alternatives by name (what they use today and why it's painful).
- A differentiator that is true and provable from the codebase.

Don't proceed until the audience is concrete enough that a stranger could spot one in the wild.

### 4. Framing interview (one question at a time)

Ask remaining questions **one at a time**. Wait for each answer before the next. Cover only what wasn't resolved in the pre-flight or hypothesis validation:

1. **Stakes** — Why does this audience care enough to switch / try? What does the pain cost them today?
2. **Non-audience** — Who is this explicitly **not** for? Naming the non-audience sharpens the positioning.
3. **Proof** — What concrete proof can we point to? Shipped features, benchmarks, contributor count, who uses it, design partners. (If proof is thin, plan content strategy around generating it.)
4. **Channels** — Where does this audience actually spend time? Be specific (Hacker News, r/golang, .NET Conf, Discord servers, dev.to, niche newsletters). No generic "social media".
5. **Tone deltas** — Is there any reason marketing voice should differ from `DESIGN.md`'s voice? Default: no. If yes, write down why and where.

Skip any question already answered by the hypothesis validation. Don't ask twice.

### 5. Propose messaging, iterate

Don't ask the user to write copy. Propose:

- **One-liner** (≤ 12 words, concrete, contains a verb the product does for the audience)
- **Tagline** (memorable, ≤ 6 words, optional)
- **Three value props** ranked by audience importance, each with a proof point
- **Messaging matrix**: rows = audience segments (1-3 max), columns = (pain → value prop → proof point → CTA)

Give the user concrete proposals; they refine or swap. Don't offer menus. Recommend one option per slot with rationale.

### 6. Channels & content strategy

Based on confirmed channels, propose:

- **Launch sequence** — what to publish first, second, third, on which channels, in what order.
- **Ongoing cadence** — what to publish weekly/monthly. Don't over-commit; pick what the team can sustain.
- **Content types** — blog, social threads, demo videos, conference talks, partnerships. Match to channel.
- **Repurposing rules** — how a single piece of content fans out across channels.

This is a plan, not a fantasy. Tie every item to a confirmed channel and a confirmed value prop.

### 7. Lock sections as decided

Write each section into `MARKETING.md` as it's confirmed. Don't wait until the end. Sections, in order:

1. **One-liner & tagline**
2. **Audience** (segments, non-audience, proof of each)
3. **Positioning** (what we are, what we're not, alternatives, differentiator)
4. **Voice** (link to `DESIGN.md` voice section; document marketing-specific deltas only)
5. **Messaging matrix** (segments × value prop × proof × CTA)
6. **Channels** (where, why, priority)
7. **Content strategy** (launch sequence, ongoing cadence, content types, repurposing)
8. **Open questions** (must be empty when locked)

### 8. Adversarial review

When `MARKETING.md` is initially complete or substantially changed, invoke the `adversarial-review` skill. Resolve all blocking findings before considering it locked. The critique looks for:

- Generic AI-slop language
- Unverifiable or false claims about the product
- Vague audience or "everyone" positioning
- Voice that contradicts `DESIGN.md` without rationale
- Channel claims with no realistic plan behind them

Apply confirmed findings, then re-lock.

### 9. Record decisions

Append the meaningful marketing decisions (audience scoping rationale, key positioning choices, channel priority reasoning) to `docs/memory/decisions.md` using the project's decision format. The detailed values live in `MARKETING.md`; the *why* lives in `docs/memory/decisions.md`.

## Iteration mode

When called to update an existing `MARKETING.md`:

1. Run the voice/positioning currency check (section 2).
2. Confirm with the user which sections are in scope to change.
3. Preserve untouched sections verbatim.
4. Update only in-scope sections; lock each one as it's decided.
5. Invoke `adversarial-review` if the change is substantial (positioning, audience, or voice). Skip it for minor channel/cadence tweaks.
6. Append the change rationale to `docs/memory/decisions.md`.

## Promo content workflow (not MARKETING.md)

For one-off promo content (landing copy, launch announcement, social thread, blog draft, README marketing section, sales/contact page copy):

- Read `MARKETING.md` first. Pull positioning, messaging, voice from it. If `MARKETING.md` doesn't exist and the content is non-trivial, ask whether to create it first via this skill.
- Write the content to `docs/marketing/<yyyy-mm-dd>_<slug>.md` (e.g. `docs/marketing/2026-05-23_landing-v1.md`).
- For marketing UI (landing pages, sales pages), produce the copy and a layout brief here, then invoke the `frontend-design` skill for the UI. Read `DESIGN.md` to keep visuals on-brand.
- Truth check: every claim must be verifiable from the codebase. If unsure, ask before publishing.

## Launch plan (GTM) workflow

A launch plan is a time-bound execution plan for a specific release, milestone, or campaign. It lives at `docs/marketing/<yyyy-mm-dd>_launch-<name>.md` (e.g. `docs/marketing/2026-05-23_launch-v1.md`). One file per launch. It does not replace `MARKETING.md` — it operationalizes it for a specific moment.

### When to create a launch plan

- A versioned release is approaching (v1.0, major feature, public beta)
- A specific campaign is planned (Hacker News launch day, conference announcement, partnership reveal)
- The user explicitly asks for a GTM plan

### Pre-flight for a launch plan

Before writing the plan:
- Read `MARKETING.md`. The launch plan pulls positioning, audience, voice, and channels from it — do not re-decide them here. If `MARKETING.md` doesn't exist and the launch is non-trivial, propose creating it first.
- Read the relevant `docs/specs/` to know exactly what ships in this launch (feature scope, known limitations, what's deferred).
- Verify claims against the codebase. Truth check is non-negotiable.

### Launch plan template

Write the launch plan to `docs/marketing/<yyyy-mm-dd>_launch-<name>.md` using this structure:

```markdown
# Launch: <name>

- **Date target**: <YYYY-MM-DD or window>
- **Status**: planning | ready | live | post-mortem
- **Source of truth**: links to MARKETING.md, relevant specs

## What's launching

Concrete feature/release scope in 3-6 bullets. What ships, what doesn't. Pull from the spec; do not embellish.

## Goal of this launch

One sentence. Pick **one** primary outcome (e.g. "300 GitHub stars in week 1", "20 design-partner signups", "10 qualified sales conversations"). A launch with three goals achieves none.

## Audience focus

Which segments from `MARKETING.md` does this launch target? Often a subset, not all of them. Name them and why this launch lands for them now.

## Core message

One-liner for this launch (may differ slightly from the durable `MARKETING.md` one-liner — that's fine, but document why).
Top 3 value props for this launch, ordered.
Proof points to lead with (specific, verifiable).

## Channel plan

Which channels (from `MARKETING.md`), in what order, with what message tweak. Be concrete:

| Channel | Day | Asset | Owner | Notes |
|---------|-----|-------|-------|-------|

## Asset checklist

Concrete deliverables, with target file paths and owner:

- [ ] Landing page copy → `docs/marketing/<yyyy-mm-dd>_<name>-landing.md`
- [ ] HN / Reddit / LinkedIn / X post drafts → `docs/marketing/<yyyy-mm-dd>_<name>-social.md`
- [ ] Blog post draft → `docs/marketing/<yyyy-mm-dd>_<name>-blog.md`
- [ ] README marketing section update
- [ ] Demo video/gif script (if applicable)
- [ ] FAQ / objections doc (if applicable)
- [ ] Email/announcement copy (if applicable)

Only include what's actually needed. Don't pad.

## Sequence

Ordered timeline, relative to launch day (T-7, T-3, T-0, T+1, T+7). Be concrete about what happens when and on which channel. Example:

- **T-7**: Internal review of all assets. Schedule HN post for T-0 morning.
- **T-3**: Soft launch to design partners / early users.
- **T-0 09:00 PT**: HN post. README + landing live. X thread.
- **T-0 +2h**: LinkedIn post.
- **T+1**: Reply to top 10 HN comments. Recap thread.
- **T+7**: Retrospective, update this file's Post-mortem section.

## Risks & mitigations

Top 3-5 things that could go wrong (server load, claim that can't survive scrutiny, audience mismatch, news cycle clash) and what to do if they happen.

## Success signals

What we'll look at to call this launch successful or not. Tie back to the Goal. Specific metrics; no vanity numbers.

## Post-mortem

Filled in after the launch. What worked, what didn't, what to do differently next time. Append meaningful learnings to `docs/memory/decisions.md`.
```

### Rules specific to launch plans

- **One goal per launch.** If you can't pick one, the launch isn't ready.
- **No vanity metrics.** "Page views" alone is not a success signal. Tie to conversion, signups, conversations, stars, design-partner intros.
- **Every asset has a path and an owner.** No "we'll figure it out".
- **Truth check on every claim.** A launch is a high-scrutiny moment; one false claim costs the trust of the whole release.
- **Sequence anchors at T-0.** Don't use absolute dates unless the launch date is locked. Relative is more reusable.
- **Post-mortem is mandatory.** A launch plan with no post-mortem section after the launch is incomplete — leave it open until filled.



## Rules

- **DO NOT engage unless explicitly invoked** by the user or required by an active feature that includes marketing artifacts. No auto-sync.
- **DO NOT write marketing fiction.** Every claim must be verifiable from the codebase. If a feature isn't built, don't market it as built.
- **DO NOT use generic marketing AI-slop.** Banned words/phrases (non-exhaustive):
  - empower, empowering, empowerment
  - delightful, delight
  - seamless, seamlessly
  - streamline, streamlined
  - next-gen, next-generation
  - revolutionize, revolutionary, game-changing
  - unlock (unless literally unlocking something)
  - supercharge, turbocharge
  - cutting-edge, bleeding-edge, state-of-the-art (unless provable)
  - "world-class", "best-in-class" (unless provable)
  - "made simple", "made easy"
  - "for everyone"
  Replace with concrete verbs and specific outcomes.
- **DO NOT use vague audiences.** "Developers" is not an audience. "Backend engineers at growth-stage SaaS shipping multi-tenant infra" is.
- **DO NOT duplicate DESIGN.md voice.** Reference it. Document only marketing-specific deltas with a rationale.
- **DO NOT define features, set priorities, or alter the roadmap.** Out of scope; use the `roadmap` skill.
- **DO NOT influence design or UI patterns.** Pull from `DESIGN.md`; don't redefine.
- **DO NOT do SEO, keyword research, analytics setup, pricing strategy, or localization** in v1. Flag and defer unless the user explicitly asks.
- **DO NOT ask 20 questions at once.** One at a time after the hypothesis validation.
- **DO NOT leave open questions** in `MARKETING.md` when locking. Resolve or defer with rationale.
- **DO NOT skip the adversarial review** on initial creation or substantial change.
- **DO NOT propose menus.** Make a concrete recommendation per slot with rationale; the user refines.
