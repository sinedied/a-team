---
name: retrospective
description: Manually reflect on the current session to improve the workflow itself. Use ONLY when the user explicitly asks — e.g. "run a retrospective", "let's do a retro", "reflect on this session", "what did we learn", "how did that go", "improve the workflow/AGENTS.md/skills". Do NOT auto-trigger, do NOT run as part of the feature loop, and do NOT use it to review code or test the app — that's `/rubber-duck` and the `qa` skill.
---

# Retrospective

Improve **how the work gets done**, not the work itself. This is self-reflection on the
**process** — the AGENTS.md workflow and the skills — so future sessions produce better
results with less friction. It is **user-triggered only**; never start a retro on your own.

Improving the code, tests, or deliverables is out of scope — that's `/rubber-duck` (static
review) and `qa` (dynamic verification).

## Procedure

1. **Gather evidence from this session.** Don't rely on memory alone — look at:
   - The **conversation**: the user's requests, your responses, and especially **friction
     signals** — corrections ("no, do X"), redo/revert requests, backtracking, rejected plans,
     wrong assumptions, repeated clarifications, tool failures, wasted or duplicated steps,
     re-reviews, and anything the user pushed back on.
   - **`plan.md`** and the **todo history** — what was planned vs. what actually happened,
     scope changes, abandoned approaches.
   - The session's **git commits** (`git log`) — churn, reverts, "fix the fix" commits.
   - (Copilot CLI helpers, if available: `/chronicle`, the session store — optional.)

2. **Analyze against the workflow.** For each friction point, trace it to a cause in the
   process: Which AGENTS.md step or skill was (or wasn't) followed? Did a missing rule, a
   vague instruction, a wrong default, or a missing skill let it happen? Also note **what
   worked** — steps/skills that clearly helped, so they're preserved.

3. **Categorize findings** — strictly about process, each backed by a concrete moment:
   - **What went well** — keep doing this.
   - **What went wrong** — friction, waste, rework, wrong turns.
   - **What to improve** — the gap behind each "went wrong".

4. **Summarize** concisely (see format). High-signal only; skip generic advice.

5. **Propose an improvement plan.** For each item, a **specific, minimal** change tied to an
   observed friction — not speculative best-practice. Choose the right home:
   - **AGENTS.md** — add/adjust a rule or step (keep it lean; it's always loaded).
   - **An existing skill** — fix a trigger, tighten a step, add a gotcha (use `skill-builder`).
   - **A new skill** — only if a repeatable workflow recurred that no skill covers (use
     `skill-builder`; apply its litmus test — would the agent get it wrong without it?).
   Present the plan and ask the user to approve, edit, or drop items.

6. **Apply (on approval).** Make the approved changes: edit `AGENTS.md` directly; use
   **`skill-builder`** for any skill create/refine/retire. Record the *why* of each change in
   `docs/memory/decisions.md`. Commit with a conventional-commit message (e.g.
   `docs: tighten AGENTS.md review step (retro)`), one logical change per commit.

7. **Offer to save the report.** Ask whether to persist the summary to
   `docs/retro/<yyyy-mm-dd>.md` (create the dir if needed). Default to not saving unless they
   want a record.

## Report format

```markdown
## Retrospective — <session topic> (<yyyy-mm-dd>)

### What went well
- <specific moment> → why it helped

### What went wrong
- <specific moment / friction> → the process cause

### What to improve
| Observation | Proposed change | Where |
|-------------|-----------------|-------|
| <friction> | <specific, minimal change> | AGENTS.md / <skill> / new skill |
```

## Gotchas

- **Manual only.** Never trigger yourself, and never fold a retro into the normal feature
  loop. Run it only when the user asks.
- **Process, not product.** Don't critique the code or test it — that's `/rubber-duck` and
  `qa`. Every finding is about *how you worked*, not *what you built*.
- **Propose before applying.** AGENTS.md and skills are the user's contract; get approval,
  then apply.
- **Evidence over opinion.** Tie every finding and change to a real moment this session.
  Litmus test for a proposed change: *"Would repeating it prevent a friction that actually
  happened?"* If not, drop it.
- **Keep AGENTS.md lean.** It's loaded every turn — prefer a tighter rule over more prose, and
  push detail into a skill instead of bloating the playbook.
- **Small, high-signal changes.** A retro that rewrites everything is a red flag. Favor a few
  precise improvements.
