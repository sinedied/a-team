# Conventions

<!-- Append new conventions at the end using this format:

### <Convention Name>
<Clear description with example if helpful>
-->

### Managed A-Team Lite Instructions
The installer owns only the block between `<!-- a-team-lite:start -->` and `<!-- a-team-lite:end -->` in `AGENTS.md`. Project-specific instructions belong outside these markers. Reinstallation may replace the managed block but must preserve all surrounding content and must never create duplicate markers.

### Direct-Execution Skills
Skills under `.github/skills/` contain conditional specialist procedures executed by the main session. They must not require a named repository agent, recreate role handoffs, hard-code a model version when Copilot provides automatic routing, or mandate commits and branches unless the workflow itself requires them.
