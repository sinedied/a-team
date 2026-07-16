---
name: qa
description: "Verify a build works from a user's perspective and that all developer workflows function. Use during the verify step after implementing a feature — run install/build/test/run commands, execute acceptance scenarios, probe happy paths and edge cases, and (for web UI) inspect the running app in a browser. Do not use for static code review (that's /rubber-duck) — this is dynamic, run-it-and-try-to-break-it testing."
---

# QA — verify it actually works

Static review (`/rubber-duck`) reads the code; **QA runs it**. Nothing ships until the app
builds, every developer command works, and the feature behaves from a user's perspective.
Use this during the workflow's verify step. This skill tests — it does **not** fix code.

## Process

1. **Understand scope.** Read the plan/spec (its **Acceptance Scenarios** and **Setup** are
   your primary test plan) and `docs/memory/decisions.md` for context. If a
   `docs/qa/<feature>_log.md` exists, re-run its scenarios to catch regressions.

2. **Validate dev workflows first.** Before testing the feature, verify every developer
   command actually works — a broken workflow is **critical** (nothing else matters if the
   app won't run):
   - Install deps (`npm install`, `pip install`, `cargo build`, …)
   - Run the app (`npm run dev`, `python main.py`, …)
   - Run tests (`npm test`, `pytest`, …) and lint/format if configured
   - Build (`npm run build`, …)
   - Every script in `package.json` / `Makefile` / etc. runs without error
   - Every command mentioned in README/docs — try each one
   - Docs match actual behavior — flag outdated instructions, wrong commands, missing steps

3. **Run acceptance scenarios.** Execute each scenario from the plan exactly; report
   pass/fail per scenario.

4. **Test happy paths.** Core flow works end-to-end? Output matches expectations? Success
   states handled?

5. **Test edge cases — try to break it.** Empty / very long / special-character inputs;
   rapid repeated actions; missing or invalid data; concurrent operations; for web: back/
   forward, refresh; network errors / slow responses where testable.

6. **Test UI visually (web apps).** Use the **`chrome-devtools`** skill on the running app:
   - Screenshots to check layout, spacing, alignment, visual consistency
   - Text overflow, clipped content, z-index, broken images
   - Responsive at mobile 375px, tablet 768px, desktop 1280px
   - Interact: click buttons, fill forms, follow links
   - Browser console for JS errors/warnings
   - Focus order and keyboard navigation
   - If chrome-devtools is unavailable, follow its auto-config steps; if still not possible,
     skip and note it in the report.

7. **Test UX.** Is success/failure feedback clear? Loading states where needed? Error
   messages helpful and actionable? Flow intuitive without docs?

8. **Report** using the format below.

9. **Update the QA log** (optional but recommended for ongoing projects). Write/append
   `docs/qa/<feature>_log.md` with scenarios tested, edge cases probed, and issues found, so
   future runs don't start from scratch. Create `docs/qa/` if missing.

## Report format

```markdown
## QA Report: <feature>

### Verdict: PASS | ISSUES FOUND

### Test Summary
- **Tested**: <what>
- **Environment**: <how the app was run>

### Dev Workflow
| Command | Result |
|---------|--------|
| `npm install` | ✅ / ❌ <error> |
| `npm run dev` | ✅ / ❌ <error> |

### Acceptance Scenarios
| # | Scenario | Result | Notes |
|---|----------|--------|-------|
| 1 | <name> | ✅ / ❌ | <details if failed> |

### Issues
<!-- only if ISSUES FOUND -->
#### <title>
- **Severity**: critical | high | medium
- **Steps to reproduce**: numbered
- **Expected**: …
- **Actual**: …
- **Screenshot**: <if from visual testing>

### Passed
<!-- brief list of what worked -->
```

## Gotchas

- **Don't report style/structure/pattern issues** — that's static review (`/rubber-duck`).
- **Don't report cosmetic nits** unless they impact usability.
- **Don't assume — actually run it.** Every command, every button. An untested "works" is
  worthless.
- **Always include reproduction steps.** An issue without a repro is useless.
- **A clean PASS is valid.** Don't invent problems.
- Fixing findings (root cause + a regression test) happens back in the main workflow, not
  here — this skill only verifies and reports.
