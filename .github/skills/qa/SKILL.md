---
name: qa
description: Validate an implemented change from developer and user perspectives. Use after non-trivial or user-facing work to run existing tests, builds, documented workflows, acceptance scenarios, edge cases, and browser checks. Runs in the main session. Do not use as a code review or before an implementation exists.
---

# Quality Assurance

Execute QA in the main session. This is a validation phase, not a separate
subagent and not a substitute for implementation review.

## Process

1. **Understand the scope**
   - Read the request, active plan or spec, relevant decisions, and changed
     files.
   - Read `docs/qa/<feature>_log.md` when it exists and rerun relevant
     regression scenarios.
2. **Choose the smallest complete validation**
   - Use the repository's existing test, lint, build, type-check, and run
     commands.
   - Start targeted and expand only when failures or shared surfaces justify it.
   - Install or restore dependencies only after manifest changes or a
     missing-dependency failure.
3. **Run acceptance scenarios**
   - Execute every scenario defined by the plan/spec.
   - For user-facing behavior, verify the full path and observable result, not
     only internal functions.
4. **Probe edge cases**
   - Empty, invalid, boundary, and unusually large inputs
   - Repeated actions and concurrency when relevant
   - Missing data, dependency, network, and permission failures
   - Refresh/navigation and loading, empty, error, and success states for UIs
5. **Test web interfaces**
   - Invoke `chrome-devtools` for live interaction, screenshots, responsive
     checks, console errors, focus order, keyboard use, and semantic structure.
   - Test mobile 375px, tablet 768px, and desktop 1280px when responsive
     behavior is in scope.
6. **Check developer experience and docs**
   - Verify changed or documented setup/run commands.
   - Confirm user-facing documentation matches actual behavior.
7. **Report**
   - Give a concise PASS or ISSUES FOUND result.
   - Include commands/scenarios executed and reproducible failures.
8. **Persist only durable QA knowledge**
   - Write or update `docs/qa/<feature>_log.md` when manual/browser scenarios,
     regressions, or findings will help future sessions.
   - Do not store routine successful command output.

## Output

```md
## QA: <feature>

### Verdict: PASS | ISSUES FOUND

### Executed
| Check | Result |
|-------|--------|
| `<command or scenario>` | PASS / FAIL |

### Issues
#### <title>
- **Severity**: critical | high | medium
- **Steps**: <reproduction>
- **Expected**: <expected result>
- **Actual**: <actual result>
```

Omit `Issues` on PASS.

## Rules

- Do not edit application code during the QA pass. Return findings to the main
  workflow, then leave QA before fixing them.
- Do not report code-structure concerns; use review for those.
- Do not claim PASS without executing the relevant checks.
- Treat broken install, build, test, or documented run workflows as blocking.
- Include reproduction steps for every reported issue.
