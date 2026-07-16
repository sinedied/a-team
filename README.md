<div align="center">

![A-Team Banner](assets/banner.svg)

# A-Team Lite

**A skill-first GitHub Copilot CLI workflow without a persistent agent squad.**

[Install](#install) · [Workflow](#workflow) · [Skills](#skills) · [Artifacts](#generated-artifacts)

</div>

A-Team Lite keeps the useful product-development guardrails—roadmaps, planning,
cross-model critique, QA, design, and marketing—while removing mandatory role
handoffs. The main Copilot session owns the work and loads specialist skills
only when they are relevant.

The `lite-gpt` branch removes eight repository agents (35.7 KB of role
instructions) and replaces the old three-pass reviewer pipeline with Copilot
CLI's built-in rubber duck. When an appropriate critic is available, the CLI
selects a contrasting Claude model for GPT sessions and a contrasting GPT model
for Claude sessions.

## Install

Run the installer from the project you want to configure.

### macOS and Linux

```bash
curl -fsSL https://raw.githubusercontent.com/sinedied/a-team/lite-gpt/setup.sh \
  | bash -s -- -v lite-gpt
```

### Windows PowerShell

```powershell
iwr -useb https://raw.githubusercontent.com/sinedied/a-team/lite-gpt/setup.ps1 -OutFile setup.ps1
.\setup.ps1 -v lite-gpt
rm setup.ps1
```

Use `-y` to confirm managed updates and file conflicts non-interactively, or
`--verbose` to print installer details.

The installer:

- adds or updates the marked A-Team Lite block in `AGENTS.md`;
- preserves project instructions outside that block;
- migrates the known unmarked Shared Memory/Visual Identity block from older
  A-Team installs;
- removes the eight known legacy A-Team agent files after confirmation while
  preserving unrelated custom agents;
- installs `DESIGN.md`, skills, and shared-memory templates;
- asks before replacing conflicting files.

> [!NOTE]
> Re-running the installer is idempotent. It updates one managed block instead
> of duplicating instructions.

## Workflow

![A-Team Lite workflow](assets/workflow.svg)

1. **Roadmap when needed** — new product features require
   `docs/specs/roadmap.md`; fixes and maintenance do not.
2. **Plan non-trivial work** — use `/plan` or Shift+Tab for architectural or
   cross-file changes.
3. **Get a second opinion** — `adversarial-review` invokes rubber duck once
   before implementing a consequential plan.
4. **Implement in the main session** — use built-in subagents only when they
   reduce context or execution time.
5. **Run QA** — the main session executes tests, acceptance scenarios, edge
   cases, and browser checks through the `qa` skill.
6. **Escalate selectively** — use `/review` for complex diffs and
   `/security-review` for security-sensitive changes.
7. **Finish** — update affected docs and memory; commit only when requested or
   required by the repository workflow.

For small, well-understood changes, plan and critique steps are intentionally
skipped.

## Skills

Skills live under `.github/skills/` and load only when their trigger matches.

| Skill | Purpose |
|-------|---------|
| **roadmap** | Create or iterate product scope, MVP cuts, dependencies, and priorities |
| **adversarial-review** | Get a high-signal critique from Copilot's contrasting-model rubber duck |
| **qa** | Execute developer workflows, acceptance, edge-case, browser, UX, and documentation checks |
| **brand** | Establish or evolve the visual identity in `DESIGN.md` |
| **frontend-design** | Plan or build distinctive interfaces constrained by `DESIGN.md` |
| **chrome-devtools** | Inspect and interact with a live Chrome browser |
| **marketing** | Define positioning and messaging, then produce launch plans and promo content |
| **skill-builder** | Create, refine, or retire repeatable project workflows as skills |

The specialist skills execute in the main session. They are procedures, not
renamed role agents.

## Visual Identity

`DESIGN.md` is the visual contract. When it is undefined, run the `brand` skill
before non-trivial UI work. `frontend-design` then uses the established colors,
typography, components, layout, voice, and motion.

Validate changes with:

```bash
npx @google/design.md lint DESIGN.md
```

## Browser Testing

The `qa` skill invokes `chrome-devtools` for live web testing when relevant.
In Copilot CLI, the skill can add the MCP server to `~/.copilot/mcp-config.json`.
Cloud-agent environments require the repository MCP configuration described in
the [GitHub documentation](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/cloud-agent/extend-cloud-agent-with-mcp).

## Shared Memory

Durable context lives in:

- `docs/memory/decisions.md` — architectural, product, and design decisions
- `docs/memory/conventions.md` — established implementation conventions

Entries are append-only so later sessions can understand why the project works
the way it does.

## Generated Artifacts

| Path | Contents |
|------|----------|
| `DESIGN.md` | Visual identity contract |
| `docs/specs/roadmap.md` | Product features, scope, ordering, and status |
| `docs/specs/` | Optional durable implementation specs |
| `docs/qa/` | Durable manual/browser scenarios and regression findings |
| `docs/memory/` | Shared decisions and conventions |
| `docs/brand/` | Optional brand reference artifacts |
| `docs/marketing/` | Marketing identity, launch plans, and promo content |

## Compatibility

A-Team Lite is optimized for GitHub Copilot CLI. Plan mode and rubber duck have
direct fallbacks in `AGENTS.md` so the workflow does not block when a client
lacks a slash command. Cross-model rubber duck review requires a GPT or Claude
main session and an available contrasting critic.
