![A-Team Banner](assets/banner.svg)

# A-Team

A squad of custom [VS Code Copilot agents](https://code.visualstudio.com/docs/copilot/customization/custom-agents) for autonomous project development. No roleplay bullshit, just gets the job done.

*"I love it when a plan comes together."* — Hannibal

## Agents

| Agent | Name | Role | Model |
|-------|------|------|-------|
| **orchestrator** | Hannibal | Leads the team, delegates to the right agent, commits after pipeline passes | Sonnet 4.6 |
| **product-manager** | Face | Scopes the mission: feature decomposition, roadmap, priorities | Opus 4.6 |
| **planner** | Amy | Creates detailed implementation specs with architecture and subtasks | Opus 4.6 |
| **designer** | Murdock | Creative UI/UX design using the `frontend-design` skill | Opus 4.6 |
| **coder** | Baracus | Builds it. Implements features, writes tests, updates docs | Opus 4.6 |
| **reviewer** | Decker | Adversarial reviews (spawned 3× with diverse models) | GPT-5.4, Gemini 3.1 Pro, Opus 4.5 |
| **qa** | Lynch | Tests the running app, never stops probing | Opus 4.6 |

## Setup

Add the agent squad to your project:

```bash
cd my-project
```

**Mac/Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/sinedied/a-team/main/setup.sh | bash
```

**Windows (PowerShell):**
```powershell
iwr -useb https://raw.githubusercontent.com/sinedied/a-team/main/setup.ps1 -OutFile setup.ps1; .\setup.ps1; rm setup.ps1
```

Files are installed in the current directory. Existing files are never overwritten without confirmation.

## Pipeline

![Pipeline](assets/pipeline.svg)

## Shared Memory

All agents read and write to `memory/`:
- `memory/decisions.md` — Architectural and design decisions
- `memory/conventions.md` — Established project conventions

## License

[MIT](LICENSE)
