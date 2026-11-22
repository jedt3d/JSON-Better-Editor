# AGENTS.md

Instructions for AI coding agents working in this repository. `CLAUDE.md` points here, so this file is the single source of truth.

## Project

JSON Better Editor: a Flutter desktop app (macOS first) for editing JSON in two switchable modes, **Text** (code editor) and **Node** (tree editor). Mockups and the original brief live in `docs/`.

## Decision log

`docs/decision-log.md` is the project's decision log. Append every new decision as a new row at the bottom of its table, numbered after the last row. Never edit or delete past rows; if a decision is reversed, add a new row that says which row it supersedes.

## Keeping the docs current

- `docs/requirements-checklist.md` is the only requirements file; it has no version suffix. Update it in the same PR whenever a decision or a merged ticket changes a requirement, and tick items that are built. Never add versioned copies.
- `docs/decision-log.md`: append decisions as described above.
- `docs/development-phases.md`: review it at the end of every phase and update it to what was actually built.

## Checkboxes, PRs and issues

Before asking for a merge, tick every checkbox that is done in the PR body and in its issue, with evidence for each. Leave a box unticked only with a note saying why (for example, moved to a later phase and the decision row). After the merge, close the issue and tick it in its parent issue's checklist. A merged PR or closed issue must never show unticked boxes without a note.

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
