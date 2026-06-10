![A-Team Banner](assets/banner.svg)

# A-Team — Game Dev Branch

> **Experimental branch.** This is the `gamedev` variant of A-Team, adapted to operate as a game development squad. The default `main` branch targets generic software/web projects. See [main](https://github.com/sinedied/a-team/tree/main) for that flavor.

A squad of custom [GitHub Copilot agents](https://code.visualstudio.com/docs/copilot/customization/custom-agents) for autonomous game development. No roleplay bullshit, just gets the job done.

*"I love it when a plan comes together."* — Hannibal

## Agents

Each agent uses whatever main model the session runs on — no models are hardcoded. The reviewer runs **2 parallel reviews** (the current main model + the opposite-provider SOTA, both at highest reasoning), followed by a consolidation pass on the current main model.

| Agent | Name | Role |
|-------|------|------|
| **orchestrator** | Hannibal | Leads the team, delegates to the right agent, commits after pipeline passes |
| **product-manager** | Stockwell | Scopes the mission: feature decomposition, milestone-driven roadmap, priorities |
| **planner** | Amy | Creates detailed implementation specs with architecture, subtasks, acceptance scenarios, and per-discipline design sections |
| **game-designer** | Murdock | Owns `docs/GAME.md` (game design contract): pillars, core loop, mechanics, systems, numbers, controls |
| **art-director** | Frankie | Owns `DESIGN.md` (visual identity) and `docs/AUDIO.md` (audio direction). Covers in-game art, UI/HUD, VFX, music brief, SFX vocabulary |
| **narrative-designer** *(on-demand)* | Tawnia | Owns `docs/NARRATIVE.md` (lore, characters, dialogue, branching). Engaged only when the game has story/dialogue ambition |
| **coder** | Baracus | Builds it. Implements features, writes tests, updates docs |
| **reviewer** | Decker | Adversarial review: opposite-provider SOTA + same-model, both at highest reasoning, then consolidated. Also reviews `docs/GAME.md` balance changes |
| **playtester** | Lynch | Tests the running build: acceptance scenarios, soft-locks, exploits, balance, performance, accessibility |
| **marketer** | Face | Mostly on-demand: positioning, messaging, Steam page, devlog, festival submissions. Owns `docs/marketing/MARKETING.md`. Auto-engages at vertical-slice / MVP completion (first creation), at project inception (lightweight tagline pass), and when a feature spec mandates marketing artifacts |

## Setup

Add the agent squad to your project:

```bash
cd my-game-project
```

**Mac/Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/sinedied/a-team/gamedev/setup.sh | bash -s -- -v gamedev
```

**Windows (PowerShell):**
```powershell
iwr -useb https://raw.githubusercontent.com/sinedied/a-team/gamedev/setup.ps1 -OutFile setup.ps1; .\setup.ps1 -v gamedev; rm setup.ps1
```

Files are installed in the current directory. Existing files are never overwritten without confirmation.

`-v` accepts any tag or branch — pin to a specific version once one is tagged.

## Skills

The squad includes built-in skills that agents use automatically:

| Skill | Used by | Description |
|-------|---------|-------------|
| **roadmap** | Product Manager | Creates or iterates on `docs/specs/roadmap.md` with milestone templates (vertical slice → alpha → beta → 1.0 → post-launch). Interview, intermediate validation, adversarial review |
| **game-design** | Game Designer | Establishes or evolves `docs/GAME.md`: pillars, core loop (30s / 5min / session), mechanics, systems, numbers, controls. Interview-style, lock-as-you-decide |
| **brand** | Art Director | Establishes or evolves visual identity in `DESIGN.md` (Google spec). Covers UI **and** in-game art direction (palette, silhouette, animation, VFX). Validates with `npx @google/design.md lint` |
| **narrative-design** | Narrative Designer | On-demand: establishes or evolves `docs/NARRATIVE.md` (setting, characters, voice, dialogue conventions, branching policy). Only invoked when narrative is in scope |
| **marketing** | Marketer | Establishes or evolves `docs/marketing/MARKETING.md` — positioning, audience, messaging, channels, content strategy. Game-aware: Steam page, capsule briefs, festival timing, press kit |
| **frontend-design** | Art Director | Guides creation of distinctive, production-grade UI that avoids generic AI aesthetics. Used for HUD, menus, and marketing pages |
| **playtest-harness** | Playtester | Engine-agnostic playtest orchestrator. Launches via the spec's `## Run Target`, captures screenshots / perf, writes structured logs to `docs/playtest/`. Works with or without engine helper skills |
| **chrome-devtools** | Playtester / Art Director | Controls a live Chrome browser for visual testing, screenshots, and DOM inspection. Auto-configures the MCP server when needed |

### Optional engine helper skills

These ship as starting points for common engines. They are **optional** — `playtest-harness` works without them by invoking the Run Target directly. Remove, replace, or extend them to match your project's stack.

| Skill | Description |
|-------|-------------|
| **engine-godot** | Godot helper: headless / windowed launch, scene loading, screenshot capture, FPS / draw-call / memory probes, export builds |
| **engine-web-2d** | Web 2D helper (Phaser / PixiJS / Kaboom / canvas): framework-aware FPS probes, console / WebGL error monitoring |
| **engine-web-3d** | Web 3D helper (Three.js / Babylon / PlayCanvas): draw-call / triangle / memory probes, WebGL context-loss detection, asset-load error capture |

<details>
<summary>Configuring chrome-devtools for GitHub Copilot cloud agent</summary>

The chrome-devtools skill auto-configures in VS Code and Copilot CLI. For the **GitHub Copilot cloud agent** (SWE agent), you need to configure the MCP server manually in your repository settings:

1. Go to your repository on GitHub.com
2. Navigate to **Settings → Code & automation → Copilot → Cloud agent**
3. Add the following to the **MCP configuration** section:

```json
{
  "mcpServers": {
    "chrome-devtools": {
      "type": "local",
      "command": "npx",
      "args": ["-y", "chrome-devtools-mcp@latest", "--headless"],
      "tools": ["*"]
    }
  }
}
```

Chrome runs in headless mode in the cloud agent environment. You may also need a `copilot-setup-steps.yml` to install Chrome in the runner — see [GitHub docs](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/cloud-agent/extend-cloud-agent-with-mcp).

</details>

## Workflow

![Workflow](assets/workflow.svg)

> The workflow diagram is from the `main` branch and reflects the generic flow. The gamedev pipeline adds: `game-designer` before any gameplay spec, `art-director` for visual **and** audio, `narrative-designer` on-demand only, and a runnable-build gate before `playtester`. Diagram update tracked in `docs/specs/roadmap.md`.

## Shared Memory

All agents read and write to `docs/memory/`:
- `docs/memory/decisions.md` — Architectural and design decisions (including game-design and balance decisions)
- `docs/memory/conventions.md` — Established project conventions

## Generated Artifacts

The agents produce artifacts during the pipeline. These are committed alongside the code:

| Path | Contents | Written by |
|------|----------|------------|
| `DESIGN.md` | Visual identity contract — colors, typography, components, voice, motion, in-game art direction. Follows [Google's DESIGN.md spec](https://github.com/google-labs-code/design.md) (must stay at repo root) | Art Director |
| `docs/GAME.md` | Game design contract — pillars, target player, references, core loop, mechanics, systems, numbers, controls, win/loss, monetization, out-of-scope | Game Designer |
| `docs/AUDIO.md` | Audio direction contract — SFX vocabulary, music brief, audio cues, mix targets, VO direction | Art Director |
| `docs/NARRATIVE.md` *(on-demand)* | Narrative contract — setting, lore, characters, voice, dialogue conventions, branching policy, spoiler boundaries | Narrative Designer |
| `docs/specs/` | Implementation specs with architecture, per-discipline design sections, subtasks, acceptance scenarios, playtest hooks, decisions | Planner |
| `docs/playtest/` | Playtest logs — scenarios tested, failure modes probed, balance observations, performance traces (persists across sessions) | Playtester |
| `docs/memory/` | Shared decisions and conventions | All agents |
| `docs/brand/` *(optional)* | HTML brand book, UI kit, and demo page derived from `DESIGN.md` | Art Director |
| `docs/marketing/` *(on-demand)* | `MARKETING.md` (positioning, messaging, channels) + dated per-engagement promo content (`<yyyy-mm-dd>_<slug>.md`), Steam page copy, trailer briefs, festival trackers | Marketer |

## License

[MIT](LICENSE)
