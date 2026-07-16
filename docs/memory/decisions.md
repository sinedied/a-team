# Decisions

<!-- Append new decisions at the end using this format:

### <Decision Title>
- **Date**: YYYY-MM-DD
- **Context**: What prompted this decision
- **Decision**: What was decided
- **Rationale**: Why this choice
- **Alternatives**: What else was considered
-->

### Skill-First Lite-GPT Architecture
- **Date**: 2026-07-16
- **Context**: The full workflow required eight repository agents, multiple role handoffs, and a three-pass reviewer protocol, increasing latency and model usage for routine feature work.
- **Decision**: The `lite-gpt` branch uses one main Copilot CLI session, a concise managed `AGENTS.md` workflow, built-in plan and review capabilities, and on-demand skills. Product management remains in `roadmap`; review and QA become direct-execution skills; design and marketing remain specialist skills.
- **Rationale**: Conditional expertise stays available without loading or invoking a persistent role pipeline. Copilot's built-in rubber duck preserves cross-provider critique with one contrasting-model pass.
- **Alternatives**: Keep an orchestrator agent, retain a smaller set of role agents, or remove the specialist procedures entirely.
