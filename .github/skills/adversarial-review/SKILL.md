---
name: adversarial-review
description: Get a high-signal, contrasting-model critique of a non-trivial plan, architecture, implementation, or test strategy. Use after preparing a consequential plan, when the user asks for a second opinion, or after repeated failures reveal likely blind spots. Do not use for trivial edits or as a substitute for executing tests.
---

# Adversarial Review

Use Copilot CLI's built-in rubber duck for one independent critique. Rubber duck
automatically selects a model from a different GPT/Claude family than the main
session; do not hard-code a model ID or recreate a persistent reviewer role.

## Process

1. **Define the artifact**
   - Identify whether the review covers a plan, architecture, code change, or
     test strategy.
   - Include the original request, relevant decisions/conventions, and the
     smallest code or diff context needed to judge correctness.
2. **Invoke rubber duck once**
   - Ask the built-in rubber duck to find substantive issues only.
   - For plans, review before implementation when course corrections are cheap.
   - For completed code, use this skill only when risk, material plan changes,
     or repeated validation failures justify another model pass.
3. **Challenge the work**
   - Is there a simpler correct design?
   - Which failure modes, edge cases, or security concerns are missing?
   - Do dependencies and ordering work?
   - Does the implementation satisfy the request and plan?
   - Do tests prove the behavior instead of merely exercising code?
4. **Filter**
   - Discard style, formatting, naming, grammar, low-confidence speculation,
     and suggestions already enforced by tooling.
5. **Resolve**
   - The main session evaluates each finding, fixes confirmed issues, and reruns
     affected validation.

## Output

```md
## Review: <artifact>

### Verdict: PASS | ISSUES FOUND

### Blocking
- **Location**: <file, section, or step>
  **Issue**: <concrete problem>
  **Fix**: <specific correction>

### Non-blocking
- <meaningful issue that should be addressed>

### Suggestions
- <optional improvement with real impact>
```

Omit empty sections. A clean PASS is valid.

## Fallback

Rubber duck is available when the main session uses a GPT or Claude large
language model and a contrasting critic is available. Otherwise perform the
same review directly, state that it was not cross-model, and continue without
blocking the task.

## Rules

- Use one default critique for a non-trivial plan, not the old multi-pass
  reviewer pipeline.
- Do not modify files during the critique.
- Do not accept findings blindly; confirm them against the codebase.
- Do not use review as evidence that tests or QA passed.
