# SFinance

Personal finance desktop app built with Flutter. Local-only — no accounts, no cloud, no telemetry.

This repository contains the source code, feature specs, and the spec-kit workflow configuration for the SFinance ecosystem.

## Structure

```
SFinance/
├── my_apps/               # Monorepo (Melos workspace)
│   ├── apps/
│   │   └── sfinance/      # Main desktop app
│   └── packages/
│       ├── shared_models/ # Pure Dart data models
│       ├── shared_ui/     # Shared widgets, theme, formatters
│       └── shared_services/ # Drift database, DAOs, period generator
├── specs/                 # Feature specifications and design artifacts
│   └── 001-sfinance-core-app/
│       ├── spec.md
│       ├── plan.md
│       ├── tasks.md
│       ├── data-model.md
│       ├── research.md
│       ├── quickstart.md
│       └── contracts/
├── .specify/              # Spec-kit workflow configuration
├── .claude/               # Claude Code skills (spec-kit commands)
└── CLAUDE.md              # Development guidelines for AI-assisted work
```

## Apps

| App | Status | Description |
|-----|--------|-------------|
| `sfinance` | Active | Personal finance tracker — income, expenses, recurring entries, dashboards |
| `dashboard` | Planned | — |

## Getting Started

See [`my_apps/apps/sfinance/README.md`](my_apps/apps/sfinance/README.md) for setup and development instructions.

## Workflow

Feature development follows the spec-kit flow:

```
/speckit.specify   → write the spec
/speckit.plan      → research + design
/speckit.tasks     → generate task list
/speckit.implement → implement task by task
```

Feature specs live in `specs/<feature-id>/`. Governing rules are in `.specify/memory/constitution.md`.
