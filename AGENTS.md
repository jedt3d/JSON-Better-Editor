# AGENTS.md

Instructions for AI coding agents working in this repository. `CLAUDE.md` points here, so this file is the single source of truth.

## Project

JSON Better Editor: a Flutter desktop app (macOS first) for editing JSON in two switchable modes, **Text** (code editor) and **Node** (tree editor). Mockups and the original brief live in `docs/`.

## Messages to the maintainer

Every message you send back for the maintainer to read falls into exactly one of three groups. Mark it with the label at the very start of the message.

1. **`[DECISION]`**: the maintainer must answer a question from you. Ask the question plainly and give your recommended answer.
2. **`[INFORM]`**: the maintainer must read this, but does not need to reply.
3. **No label**: a log of what you did. The maintainer may or may not read it, so never put a question or anything they must know in an unlabelled message.

If a message contains both a question and information, label it `[DECISION]`.

## Agent skills

### Issue tracker

Issues are tracked in this repo's GitHub Issues (`gh` CLI). See `docs/agents/issue-tracker.md`.

### Triage labels

Default vocabulary: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `CONTEXT.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.
