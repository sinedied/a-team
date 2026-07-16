---
name: skill-builder
description: Create, refine, or retire project skills for repeatable workflows the base agent would otherwise handle unreliably. Use when the user explicitly asks to add or change a skill, or repeated failures show that a specialized procedure should be captured. Do not use for one-off tasks, generic coding guidance, or rules that belong in AGENTS.md.
---

# Skill Builder

A skill teaches the main agent a repeatable, conditional workflow it would not
reliably perform without extra guidance. The test for every skill and every line
is: **would the agent get this wrong without it?** If not, leave it out.

## Format

A skill lives at `.github/skills/<name>/SKILL.md` with YAML frontmatter and a
Markdown procedure. It may include `scripts/`, `references/`, or `assets/`.

```md
---
name: <lowercase-hyphenated-name>
description: <activation rule with positive and negative triggers>
---

# <Title>

<ordered procedure, defaults, validation>

## Gotchas
- <concrete non-obvious mistake>
```

Names use lowercase letters, digits, and hyphens, are at most 64 characters,
and match the folder name.

## Description First

The description is the activation function and usually the only content visible
before loading:

- Start with the user's intent: "Use when..."
- Front-load likely prompt words and scenarios.
- Include negative triggers: "Do not use for..."
- Keep all trigger logic in the description, not the body.
- Stay below 1024 characters.

## Keep Skills Lean

- Put only conditional specialist procedure in the body.
- Give defaults instead of equal menus.
- Move bulky or optional detail into `references/` and state exactly when to
  read each file.
- Add scripts only for deterministic, fragile, repetitive, or token-heavy work.
- Scripts must be non-interactive, idempotent, diagnostic, and require explicit
  confirmation for destructive actions.
- Skills execute in the main session. Do not wrap a role in a custom agent or
  recreate a handoff pipeline.

## Creating

1. Clarify the trigger, inputs, outputs, fragile steps, and definition of done.
2. Reject the skill if AGENTS.md, a built-in capability, or a one-off prompt is
   sufficient.
3. Choose the name and write the description before the body.
4. Scaffold `.github/skills/<name>/SKILL.md`; add supporting files only when
   needed.
5. List prompts that should activate it and near misses that should not.
6. Validate the procedure against one representative task.

## Refining

1. Read the current skill and identify the observed failure.
2. Make the smallest change that fixes it.
3. Keep the description synchronized with behavior.
4. Recheck positive and negative trigger examples when the description changes.

## Retiring

1. Confirm the workflow is obsolete or reliably covered elsewhere.
2. Remove the skill folder and any references to it.
3. Verify no active workflow depends on it.

## Trigger Sanity Check

Should load:

- "Create a skill for our release checklist."
- "Refine the roadmap skill so bug fixes do not trigger it."
- "Retire the old deployment skill."

Should not load:

- "Fix this bug."
- "Write a one-off migration."
- "Explain this API."

## Rules

- Target the open `SKILL.md` format and note real compatibility requirements.
- Do not mandate a branch, commit, or provider unless the workflow genuinely
  requires it.
- Do not weaken repository privacy, security, or quality rules.
- Prefer one focused skill over a broad persona.
