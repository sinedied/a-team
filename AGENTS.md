# Project Guidelines

## Shared Memory

The project maintains shared memory in `memory/`:

- `memory/decisions.md` — Architectural and design decisions
- `memory/conventions.md` — Established project conventions
- `memory/brand.md` — Visual identity (colors, typography, components, voice). Owned by the `design-director` agent; read by `designer`, `planner`, and `coder` before any UI work.

### Reading
Before making architectural decisions or proposing changes, check existing decisions and conventions for prior context. For any UI work, read `memory/brand.md` first — if `Status: Defined` is `no`, the visual identity has not been established and the `design-director` agent should be invoked before non-trivial UI work.

### Writing
When a new decision is made or convention established:
1. Read the current file
2. Append the new entry at the end
3. Do not modify or remove existing entries

`memory/brand.md` is the exception: it is a structured living document, owned by the `design-director` agent. Other agents must not edit it — they flag gaps back so the design-director can extend it.

**Decision format:**
```
### <Decision Title>
- **Date**: YYYY-MM-DD
- **Context**: What prompted this decision
- **Decision**: What was decided
- **Rationale**: Why this choice
- **Alternatives**: What else was considered
```

**Convention format:**
```
### <Convention Name>
<Clear description with example if helpful>
```
