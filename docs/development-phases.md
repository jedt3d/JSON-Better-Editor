# JSON Better Editor — Development Phases

> Rough task breakdown by phase, agreed with Jedt on 2026-11-22.
> Section numbers (e.g. §1.3) refer to [`requirements-checklist.md`](requirements-checklist.md). Phase decisions are logged in [`decision-log.md`](decision-log.md).
> Platform: Flutter desktop, macOS only (macOS 14+, Flutter 3.50.1+).
> Reviewed at the end of every phase so it matches what was actually built. The Thai user reference manual, [`manual/reference.th.md`](manual/reference.th.md), is reviewed at the same time (decision #84).

Each phase ends with an app that builds and runs on macOS. A phase starts only after the previous one works.

---

## Phase 1 — Bootstrap (done 2026-11-22)

Goal: the application is up and running on macOS with very basic features, and the foundations later phases build on.

- [x] Create the Flutter macOS project, folder structure, lint and test setup.
- [x] Basic Material 3 theme (§3.6). Full One Light / One Dark comes in Phase 4.
- [x] i18n scaffolding with English as the default language (§3.7). Thai strings and the switch come in Phase 4.
- [x] Main window and toolbar skeleton (§3.2): New, Open, Search, Layout toggles, Language, Theme, Settings. Buttons can be placeholders.
- [x] Shared JSON document model used by both Text and Node panes (§1.2). Covers all six types, including Null.
- [x] Open, Save and Save As for `.json` files (§3.4).
- [x] Invalid JSON on open: error dialog with position, file not opened (§1.2).
- [x] Plain text view of the opened document (no highlighting yet).
- [x] Local build-and-test script (`scripts/check.sh`) and a smoke test that the app launches on macOS. No GitHub Actions (decision #34).
- [x] Added during the phase: Flutter 3.50.1 so Release builds work with Xcode 27, and the move to `material_ui` (decisions #44, #45).
- [x] Added during the phase: toolbar in the title-bar row with a native macOS look, document title under it, window sized from the usable work area (§3.2, §3.8; decisions #46, #48, #50).

**Done when:** you can open a valid `.json` file, see its text, save it, and an invalid file shows an error dialog. Confirmed in the Release app (issue #2).

---

## Phase 2 — Text mode complete (tech base)

Goal: every Text-mode feature and the file/editor basics, on top of the Phase 1 base.

Tracked in issue #25 (sub-issues #26–#45, about 2–3 acceptance criteria each; decision #52).

- [x] Syntax highlighting, line numbers, bracket and quote matching (§1.1). #33, #34, #35; editor component re_editor (#26, decision #60), kept as our own fork in `packages/re_editor/` (#70, decision #81).
- [x] Fold/unfold objects and arrays from the gutter (§1.1). #36; a folded block is one line (decision #72).
- [x] Key autocomplete from existing keys, accepted with Enter/Return (§1.3). #40 (decision #75).
- [x] Tab / Shift+Tab indent and de-indent text (§1.4). #37.
- [x] Copy, cut and paste with normal text-editor behavior (§1.4). #38; the template Edit menu now reaches the Text pane (decision #73).
- [x] Word wrap toggle for Text mode (§1.5). #39, View › Word Wrap (Opt+Z) (decision #74).
- [x] Search keys and values with Next / Previous (§3.3), Text mode side. #41, #42 (decision #76).
- [x] Undo / redo in Text mode (§3.5). #43; skips caret-only and fold steps (decision #78). The shared Text/Node history is Phase 3 (decision #53).
- [x] New creates an editable document; Save with no file yet behaves like Save As (§3.4, decision #43). #28, #29. Unsaved-changes prompt and edited marker: #30 (decision #55).
- [x] Standard File menu: New, Open, Save, Save As, Close; one document per window, multiple instances (§3.4). #31, #32 (decisions #67, #68).
- [x] Register as a `.json` handler in "Open With" (§3.9). #32 (decisions #56, #69).
- [x] Check performance with files under 5 MB (§3.4). #44: 5 MB opens in 0.5 s, capacity about 30 MB (`docs/performance.md`, decision #79). Jump-to-top freeze fixed in the fork (#71, decision #82). Remaining: first key suggestion, #67.

Built beyond the original list, found while checking the real app: the Edit menu items were greyed out (#38), Opt+Z typed "Ω" (#39), menu shortcuts reached the document behind a dialog (#54), and quadratic line loops in re_editor (#44). Every choice made without the maintainer is listed in `docs/phase-2-review.md`.

**Done when:** the app works as a complete JSON text editor on its own. ✅ Confirmed in the Release app on 2026-11-22 (#45, `docs/screenshots/45-phase2-done.jpg`).

---

## Phase 3 — Node Visualization

Goal: introduce the Node pane, and with it the split view and two-way sync.

### 3a. Tree view
- [ ] Tree with indentation and guide lines (§2.1).
- [ ] Row layout, type icons and colors, `{n}` / `[n]` badges, delete icon (§2.2).
- [ ] Expand all, collapse all, expand to depth, collapse siblings (§2.1).
- [ ] Select on single-click; single/multi-line value toggle, 10-line limit (§2.3).
- [ ] Word wrap for long String/Number values (§2.2).

### 3b. Editing
- [ ] Double-click to edit key and value (§2.4).
- [ ] Type dropdown with manual-conversion popup (§2.4).
- [ ] Delete with confirmation, default Cancel (§2.4).
- [ ] `+ ADD` inline new-node row (§2.5).

### 3c. Moving and clipboard
- [ ] Drag and drop one node with an insertion line (§2.6).
- [ ] Tab / Shift+Tab to indent and de-indent nodes (§2.6).
- [ ] Copy/cut one node; Cmd+V child, Cmd+Shift+V sibling after, Cmd+Opt+V sibling before; context menu (§2.7).

### 3d. Split view and sync
- [ ] Side-by-side 50/50 layout with splitter; Text only / Node only / Split toggles (§3.1).
- [ ] Two-way content sync, scroll percentage and selection sync (§3.1).
- [ ] Blank node while Text has invalid JSON, sync delay ≤250 ms (§3.1).
- [ ] One shared undo history across both panes (§3.5, decision #53).
- [ ] Search works in Node mode too (§3.3).

### 3e. Rich value previews
- [ ] Detect `data:image/...;base64,` values, 64×64 center-crop thumbnail, full-image popup (§2.8).
- [ ] Detect HTML/Markdown, edit in a syntax-highlighted popup editor, no rendering or scripts (§2.8).

**Done when:** both panes work side by side and every edit in one appears in the other.

---

## Phase 4 — Settings

Goal: the Settings screen and everything it controls.

- [ ] Settings screen from the gear icon (§3.10).
- [ ] Atom One Light / One Dark themes, follow macOS appearance by default, toolbar toggle overrides (§3.10).
- [ ] Default fonts: IBM Plex Sans (UI), IBM Plex Mono (keys/types, Text mode), IBM Plex Sans Thai Looped (values); not bundled (§3.10).
- [ ] Choose a system monospace font, replacing Plex Mono in Text mode and Node keys/types (§3.10).
- [ ] Fallback to the macOS default monospace font when a font is missing (§3.10).
- [ ] Document-wide default for single-line or multi-line values (§3.10, §2.3).
- [ ] Full Thai translation and the toolbar language switch; English on first launch (§3.7).

### Release readiness (closed-source sale)
- [ ] About menu and licenses page listing every bundled package, including the forked re_editor (§3.11). #78
- [ ] highlight.js BSD-3 notice registered with `LicenseRegistry.addLicense`, because re_highlight is a port of it (§3.11). #78
- [ ] Replace the default Flutter app icon with the app's own icon (§3.11). #78

**Done when:** every setting in §3.10 works and persists between launches, and the release items in §3.11 are done.
