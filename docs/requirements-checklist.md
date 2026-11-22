# JSON Better Editor — Requirements Checklist

> Sources: `prompt.txt`, `JSON Visual Editor Mockup.webp`, `Toolbar.png`, and Jedt's edits and answers (2026-11-22).
> Mockup and toolbar are **references only**, not strict designs.
> This file holds requirements only. Decisions and their history are in [`decision-log.md`](decision-log.md).
> This is the single, current version (no version suffix). `[x]` means built and merged; update it whenever a decision or a merged ticket changes a requirement.
> Last updated: 2026-11-22, end of Phase 1.

**Platform:** Flutter desktop app, **macOS only** (macOS 14 or later). Built with Flutter 3.50.1+ and the `material_ui` package (decisions #1, #36, #44, #45). Windows and Linux may come later with their own OS-specific code.
**Core idea:** one document shown as **Text** (code editor) and **Node** (visual tree editor). Side-by-side by default, with toggles for Text only and Node only.

---

## 1. Text mode (code editor)

### 1.1 Open and display
- [x] Open a `.json` source file from disk (native file picker limited to `.json`).
- [ ] Syntax highlighting: keys, strings, numbers, booleans, null, brackets and punctuation in distinct colors.
- [ ] Bracket matching and quote matching (highlight the matching `{}` / `[]` / `""`).
- [ ] Line numbers in a gutter.
- [ ] Collapsible hierarchy: fold/unfold objects `{}` and arrays `[]` from the gutter.

### 1.2 JSON understanding and validation
- [x] Parse key-value pairs, objects, arrays, and data types: String, Number, Boolean, Object, Array, Null. Key order, duplicate keys and number text are kept as written; nesting deeper than 512 levels is rejected (decisions #39, #40).
- [x] If a file being opened is invalid JSON, show the error position (line and column) in a dialog and do **not** open the file; the document already open stays.

### 1.3 Autocomplete
- [ ] Autocomplete a `key` from keys that already exist in the document.
- [ ] Accept the selected suggestion from the popup list with **Enter/Return** only (Tab is not used to accept).

### 1.4 Keyboard and clipboard
- [ ] **Tab** / **Shift+Tab** indent and de-indent text by 2 spaces, as in a normal code editor (decision #57).
- [ ] Copy, cut and paste follow normal text-editor behavior (no node-aware paste in Text mode).

### 1.5 Word wrap
- [ ] Word-wrap toggle: View menu item (Opt+Z), off by default (decision #58).
- [ ] When on, long lines wrap to the pane's width.

---

## 2. Node mode (visual tree editor)

### 2.1 Tree visualization
- [ ] Node-based visualization of the source JSON.
- [ ] Nested nodes are indented, with vertical guide lines connecting children to their parent (as in the mockup).
- [ ] Expand/collapse across multiple levels at once:
  - [ ] Expand all / collapse all.
  - [ ] Expand to a chosen depth.
  - [ ] Collapse siblings (e.g. all items of an array).

### 2.2 Node row layout
- [ ] Row layout: `+ [ data-type icon | json key : json value ------ (# of children) | delete icon ]`
  - [ ] `+` is the expand/collapse chevron, shown only for Object/Array nodes.
  - [ ] `------` is flexible space: left group (icon, key, value) aligns left, right group (child count, delete) aligns right.
  - [ ] Child count badge: `{n}` for objects, `[n]` for arrays.
  - [ ] Delete icon (`×`) at the far right of every row.
- [ ] Data-type icons, one color per type:
  - [ ] Object: cube outline icon.
  - [ ] String: green "S" icon.
  - [ ] Number: blue "12" icon.
  - [ ] Array: purple `[ ]` icon.
  - [ ] Boolean: orange power icon.
  - [ ] Null: gray `?` icon.
- [ ] Leaf key text uses its type color (green for String, blue for Number, and so on).
- [ ] Leaf value shown in a muted color in its own column, aligned across sibling rows.
- [ ] Word wrap (same toggle as 1.5) also wraps String and Number values that are longer than one line or overflow the right edge of the window.

### 2.3 Selecting and viewing
- [ ] Single-click a node selects it (for copy, cut, paste, drag, delete, indent).
- [ ] Single-click also toggles that node's value between single-line and multi-line view.
- [ ] Multi-line view shows up to **10 lines** (fixed) plus a scrollbar.
- [ ] The setting in 3.10 sets the default (single or multi-line) for the whole document; clicking a node toggles that node only.

### 2.4 Editing in the tree
- [ ] Double-click the key to rename it.
- [ ] Double-click the value to edit it.
- [ ] While editing a key or value field, clipboard shortcuts behave as normal text paste inside the field.
- [ ] Single-click the data-type icon to open a dropdown to change type: Object, String, Number, Array, Boolean, Null.
- [ ] On a type change, no automatic parsing or conversion: show a popup with the current value so the user defines or converts the new value manually.
- [ ] Delete with the `×` icon asks for confirmation. The default button is **Cancel**.

### 2.5 Adding nodes (from the mockup)
- [ ] `+ ADD` row at the end of each container's children, aligned with that level's guide line.
- [ ] Clicking `+ ADD` opens an inline new-node row with:
  - [ ] Name field (key). For an Array parent, the Name field is hidden and replaced by the index.
  - [ ] Type dropdown (default String): Object, String, Number, Array, Boolean, Null.
  - [ ] Value field.
  - [ ] Confirm (blue check) and cancel (`×`). The default button is **Confirm**.

### 2.6 Moving nodes
- [ ] Drag and drop to move a node, one node at a time (Node mode only).
- [ ] An insertion line shows exactly where the dragged node will land.
- [ ] **Tab** indents the selected node with its children: it becomes the last child of its previous sibling.
- [ ] **Shift+Tab** de-indents the selected node with its children: it becomes a sibling of its parent, placed right after the parent.

### 2.7 Copy, cut and paste
- [ ] Copy or cut one node at a time (with its children). Multi-node copy/cut is not allowed.
- [ ] Paste shortcuts:
  - [ ] **Cmd+V**: paste as child of the selected node (when a node is selected and no field is being edited).
  - [ ] **Cmd+Shift+V**: paste as sibling **after** the selected node.
  - [ ] **Cmd+Opt+V**: paste as sibling **before** the selected node.
- [ ] The same paste options are in the context menu.

### 2.8 Rich value previews
- [ ] On file load, detect String values that are images in data-URI form: `data:image/<type>;base64,<data>`. Raw base64 without the prefix is not detected.
- [ ] Show a **64×64 px** thumbnail, center-cropped so the shorter side fits.
- [ ] Click the thumbnail to open a popup with the full image.
- [ ] Detect HTML and Markdown content in String values.
- [ ] Open HTML/Markdown in a popup **syntax-highlighted text editor** only. No rendered preview, and scripts never run.
- [ ] Edits in the popup are saved back to the node's value.

---

## 3. General features

### 3.1 Layout and sync
- [ ] Default layout: Text and Node side by side, 50/50, with a draggable splitter.
- [ ] Toolbar has three layout toggles: **Text only**, **Node only**, **Split 50/50**.
- [ ] Edits in either pane are reflected in the other.
- [ ] Scroll position (by percentage) and the selected node/value are synced between panes.
- [ ] While Text contains invalid JSON, Node mode shows a **blank node** (not a partial tree). Sync delay up to 250 ms is acceptable.

### 3.2 Toolbar (based on Toolbar.png)
- [x] The toolbar shares the title-bar row with the macOS window controls (traffic lights), vertically centred on them (decision #46).
- [x] Native macOS look: borderless icon buttons that show a rounded fill only on hover and press, like Xcode, Finder and Safari (decision #50). Other OSes get their own toolbar style later.
- [x] Empty toolbar space behaves like a title bar: drag to move the window; double-click follows the system setting (zoom by default).
- [x] Left group:
  - [x] New (file icon).
  - [x] Open file (folder icon).
  - [x] Divider.
  - [x] Search (button in place; search itself is §3.3).
- [x] Right group (left to right), buttons in place; their features are in the sections named:
  - [x] Layout toggles: Text only / Node only / Split 50/50 (§3.1).
  - [x] Language switch (Thai / English) (§3.7).
  - [x] Theme toggle (half-filled circle), light/dark (§3.9).
  - [x] Settings (gear), at the far right (§3.9).
- [x] Document title shown under the toolbar (file name, or the app name when nothing is open).

### 3.3 Search
- [ ] Search both keys and values.
- [ ] Jump to the first match, with **Next** / **Previous** to move between matches.
- [ ] Works in both Text and Node mode.

### 3.4 File operations
- [x] Open, Save (Cmd+S) and Save As (Cmd+Shift+S, save panel limited to `.json`); Save As makes the new path the current file.
- [ ] Save with no file yet behaves like Save As. Applies once New creates an editable document (Phase 2, decision #43).
- [ ] Standard File menu items with normal macOS behavior: New, Open, Save, Save As, Close.
- [ ] Save with invalid JSON in the Text pane shows the error dialog with line and column and does not write the file (decision #54).
- [ ] Unsaved changes are marked in the window; New, Open, Close and Quit ask Save / Don't Save / Cancel, default Save (decision #55).
- [x] Save reformats the JSON (pretty-print, 2-space indent) before writing, and the file ends with a newline (decisions #28, #47).
- [x] A failed write shows an error dialog, keeps the document open, and puts the file's previous contents back (decision #42).
- [ ] One document per window. The app can run multiple instances.
- [ ] Target for now: files under 5 MB: open and show in 2 s or less, no visible lag when typing, scrolling or searching (decision #59). The largest file that opens within 2–3 s is measured and recorded as the current upper limit. Progressive loading/rendering is future work.

### 3.5 Undo / redo
- [ ] Undo and redo are required (Cmd+Z / Cmd+Shift+Z).
- [ ] One shared undo history across the Text and Node panes.

### 3.6 Design system
- [x] All other UI follows conventional Material 3 design (basic light and dark theme following the system; One Light / One Dark in §3.9).

### 3.7 Language
- [ ] UI supports Thai and English, switched from the toolbar button.
- [x] UI language is always English on first launch (all UI strings go through the localization files).
- [ ] Thai text renders correctly in keys and values.

### 3.8 Window
- [x] The window opens at 60% of the width × 80% of the height of the usable work area (screen minus menu bar and Dock), centred, on the main screen (decisions #46, #48).
- [x] It can be shrunk to about 20% × 20% of the usable work area; below the toolbar's natural width the toolbar is cut off without errors. On macOS the height stops at about 216 pt.
- [x] Sizes are never fixed in pixels, because HiDPI scaling differs per machine; they are fractions of the usable work area (future Windows: minus the taskbar; Linux/Ubuntu: minus the dock).

### 3.9 OS integration
- [ ] Register as a handler for `.json` on macOS, so it appears in "Open With" and can be set as the default editor. Opening a file from Finder while the app runs replaces the window's document after the unsaved-changes prompt (decision #56).

### 3.10 Settings (gear icon, top-right)
- [ ] Theme: Atom **One Light** and **One Dark**. Follows the macOS appearance by default; the toolbar toggle overrides it.
- [ ] Monospace font chosen from fonts installed on the system. It replaces IBM Plex Mono in **both** the Text mode editor and Node mode keys/types.
- [ ] Default fonts (not bundled with the app, loaded from the system):
  - [ ] UI: IBM Plex Sans.
  - [ ] Key and data type: IBM Plex Mono.
  - [ ] Value: IBM Plex Sans Thai Looped.
- [ ] If a default font is not installed, fall back to the macOS default monospace font.
- [ ] Default value view for the document: single-line or multi-line (see 2.3).
