# JSON Better Editor — Requirements Checklist (Draft v0.1)

> Source: `prompt.txt` (feature list), `JSON Visual Editor Mockup.webp`, `Toolbar.png`.
> Mockup and toolbar are **references only**, not strict designs.
> Status: draft for review. Edit freely; items marked `(?)` link to an open question at the end.

Platform: Flutter desktop app, macOS only.
Core idea: one document, two switchable modes, **Text** (code editor) and **Node** (visual tree editor), similar to Markdown Code/Preview.

---

## 1. Editor side (Text mode)

### 1.1 Open and display
- [ ] Open a `.json` source file from disk.
- [ ] Display the source with syntax highlighting (keys, strings, numbers, booleans, null, brackets, punctuation in distinct colors), match parenthesis and quote, double quotes.
- [ ] Show line numbers in a gutter (as in the mockup's dark code pane).
- [ ] Collapsible hierarchy: fold/unfold objects `{}` and arrays `[]` from the gutter.

### 1.2 JSON understanding
- [ ] Parse and understand key-value pairs, objects, arrays, and data types (String, Number, Boolean, Object, Array, Null ).
- [ ] Report invalid JSON (position of the error in a dialog box) without open the invalid file.

### 1.3 Autocomplete
- [ ] Autocomplete a `key` from keys that already exist in the document. Accept a key from popup list with Tab or Enter/Return key.

### 1.4 Drag and drop (?)
- [ ] Drag and drop one tree node (one by one) to move them.
- [ ] Show an insertion line indicating exactly where the dragged node will be inserted.

### 1.5 Copy and paste (?)
- [ ] Copy a node.
- [ ] Copying multiple sibling nodes at once is prohibited.
- [ ] Paste can insert **before** or **after** or as Child the selected node. Pop up menu to choose or contextual menu items. Ctrl/Cmd+Shift+V for insert **after** and Ctrl/Cmd+Alt/Opt+V for insert **before** and Ctrl/Cmd+V to past **as child**

### 1.6 Word wrap
- [ ] Word-wrap toggle.
- [ ] When on, node content wraps to the window's width.

---

## 2. Visual side (Node mode)

### 2.1 Tree visualization
- [ ] Show a node-based visualization of the source JSON.
- [ ] Nested nodes are indented, with vertical guide lines connecting children to their parent (as in the mockup).
- [ ] Show/hide (expand/collapse) collapsible nodes across multiple levels at once (e.g. expand all, collapse all, expand to level N (?) ).

### 2.2 Node row layout
- [ ] Each row follows this layout:
  `+ [ data-type icon | json key : json value ------ (# of children) | delete icon ]`
  - [ ] `+` is the expand/collapse control (chevron in the mockup), shown only for Object/Array nodes.
  - [ ] `------` is flexible space, so the left group (icon, key, value) aligns left and the right group (child count, delete) aligns right.
  - [ ] Child count badge for containers, e.g. `{2}` for objects and `[n]` for arrays (?).
  - [ ] Delete icon (`×`) at the far right of every row.
- [ ] Data-type icons with a color per type (from the mockup):
  - [ ] Object: cube outline icon.
  - [ ] String: green "S" icon.
  - [ ] Number: blue "12" icon.
  - [ ] Array: purple `[ ]` icon.
  - [ ] Boolean: orange power icon.
  - [ ] Null: gray icon with `?`.
- [ ] Key text uses the type color for leaf nodes (green key for String, blue for Number, and so on), as in the mockup.
- [ ] Leaf value shown in a muted color in its own column, aligned across sibling rows.

### 2.3 Editing in the tree
- [ ] Single-click the data-type icon to open a dropdown menu to change the node's data type (Object, String, Number, Array, Boolean, Null ).
- [ ] If the value changes from type conversion, it must pop up the current value for the user to define or convert manually. No data parsing or automatic conversion .
- [ ] Single-click a node to show its value expanded from one line to multiple lines, showing up to 10 lines plus a scrollbar.
- [ ] Double-click the key to rename it.
- [ ] Double-click the value to edit it.
- [ ] Delete a node with the `×` icon with confirmation and default button to Cancel.

### 2.4 Adding nodes (from the mockup)
- [ ] `+ ADD` row at the end of each container's children, aligned with that level's guide line.
- [ ] Clicking `+ ADD` opens an inline new-node row with:
  - [ ] Name field (key).
  - [ ] Type dropdown (defaults to String), listing Object, String, Number, Array, Boolean.
  - [ ] Value field.
  - [ ] Confirm button (blue check) and cancel (`×`) with default button to Confirm.
- [ ] For an Array parent, the Name field is hidden or replaced by the index.

### 2.5 Rich value previews
- [ ] Detect values that are base64-encoded images and build a thumbnail preview (an initial detection pass when the file loads).
- [ ] Click the thumbnail to open a popup with the full image.
- [ ] Detect HTML and Markdown content in string values.
- [ ] Open HTML/Markdown in a popup viewer that renders a preview by default.
- [ ] The popup has a toggle to edit the source, with syntax highlighting.
- [ ] Edits in the popup are saved back to the node's value.

---

## 3. General features

### 3.1 Modes and sync
- [ ] The editor should be open side by side between text and node, base 50/50%, but be able to resize the splitter. The toolbar should have three mode toggles: text only, node only, and 50/50. 
- [ ] Edits in either mode are reflected in the other also percentage of scroll bar and selected node/value.

### 3.2 Toolbar (based on Toolbar.png)
- [ ] Rounded, pill-shaped icon buttons on a toolbar sharing the title bar row with the macOS window controls.
- [ ] Left group:
  - [ ] New (file icon)
  - [ ] Open file (folder icon)
  - [ ] Divider
  - [ ] Search
- [ ] Right group:
  - [ ] Theme toggle (half-filled circle icon), switching light/dark.
  - [ ] Settings (gear), at the top right.
- [ ] Document title shown under the toolbar (as in the reference).

### 3.3 Design system
- [ ] All other UI follows conventional Material 3 design.

### 3.4 Language
- [ ] UI supports Thai and English.
- [ ] Thai text renders correctly in keys and values.

### 3.5 OS integration
- [ ] Register as a handler for `.json` on macOS so the user can set it as the default editor.
- [ ] Same on Windows.

### 3.6 Settings (gear icon, top-right)
- [ ] Theme: a light and a dark theme similar to One Light and One Dark.
- [ ] Choose the monospace font from fonts installed on the system (?).
- [ ] Default fonts:
  - [ ] UI default: IBM Plex Sans family.
  - [ ] Key and data type: IBM Plex Mono.
  - [ ] Value: IBM Plex Sans Thai Looped (?).
- [ ] Toggle to show node values as multiple lines or a single line.

---

## 4. Open questions and clarifications

These came up while writing the checklist. I have not decided any of them. Please answer or edit inline.

1. **Null type.** JSON has `null`, but the mockup's type list has only Object, String, Number, Array, Boolean. Should Null be a type with its own icon? : Yes, add Null type
2. **Drag and drop location.** It is listed under Editor side, but it talks about "tree nodes". Is it meant for Node mode only, Text mode (folded blocks), or both? : Node mode only
3. **Copy/paste rule.** "Copy multiple sibling nodes is prohibited" — does it mean only one node can be copied at a time? Is multi-select used for anything else (drag, delete)? Is copy/paste for Node mode, Text mode, or both? Paste "before/after": should "paste as child" also exist?
 : Yes, copy/cut one at a time
 : drag & drop only one at a time
 : Copy/Cut & Paste in both mode but drag and drop in Node mode only.
 : Paste can insert **before** or **after** or as Child the selected node. Pop up menu to choose or contextual menu items. Ctrl/Cmd+Shift+V for insert **after** and Ctrl/Cmd+Alt/Opt+V for insert **before** and Ctrl/Cmd+V to past **as child**
 : Selected Node and their children can be Indented and De-indented by using Tab and Shift+Tab respectively too.
4. **Mode layout.** The goal says two *switchable* modes, but the mockup shows code and tree side by side. Switch only, side-by-side only, or both (with a layout option)?
 : answer above, 3 modes toggle button
5. **Sync timing.** When Text mode contains invalid JSON, what should Node mode show? Block switching, show the last valid tree, or show the error?
 : show as a blank node or display only the correct part in Key or Value. 250ms delayed is acceptable.
6. **Expand/collapse levels.** Which controls are wanted: expand all, collapse all, expand to a chosen depth, or collapse siblings? : Yes, all/chosen depth/collapse siblings such as array
7. **Child count badge.** The mockup uses `{n}` for objects. Should arrays use `[n]`? : Yes
8. **Single-click vs double-click.** Single-click on a node expands its value view, and double-click on the key or value edits it. Should single-click also select the node (for copy/drag/delete)? : Yes
9. **Multi-line value.** Settings has a single-line/multi-line toggle, and single-click also expands to 10 lines. Is the 10-line limit fixed or a setting? Does the toggle apply to all nodes at once? : Fix, apply to each toggled node
10. **Type change conversion.** When the type changes (e.g. String "123" to Number, or Object to Array), should the value convert, be cleared, or be blocked with a warning? : Answer above
11. **Delete confirmation.** Delete a node immediately (with undo) or ask first? Is undo/redo required in general? : Answer above
12. **HTML/Markdown detection.** Detect automatically by content, by key name, or let the user choose "Open as HTML/Markdown" from a menu? Should HTML preview run scripts (security)? : Ok, use only the syntax highlighted text editor only. Try to detect syntax but do not run the script at all
13. **Base64 images.** Only `data:image/...;base64,` URIs, or also raw base64 strings? Any size limit for thumbnails? : Yes
14. **Fonts.** "Choose monospace font from system" vs default IBM Plex Mono: does the chosen font replace IBM Plex Mono for keys/types, for the Text mode editor, or both? The prompt says "IBM Plex Thai Looped"; the actual family name is "IBM Plex Sans Thai Looped". Is that the one? Should these fonts be bundled with the app? : Yes that what I mean
15. **Themes.** "One light, one dark" — the Atom/VS Code themes *One Light* and *One Dark*? The mockup's code pane is a dark purple, which is not One Dark. Which one wins? Does the theme toggle follow the OS setting by default? : Use the Atom One Light and One Dark theme
16. **Toolbar buttons.** What should Star, Menu (hamburger), and New's dropdown do in this app? (For example: Star = favorites/recent files, Menu = sidebar, New dropdown = templates such as empty object / empty array.) : Answer above
17. **Search.** Search keys only, values only, or both? Is replace needed? Does it work in both modes? : Both, then go to the first match only.
18. **Save behavior.** Save, Save As, auto-save, and formatting on save (indent size, sort keys, minify) are not listed. Are they in scope? : Yes create standard menu items for these file operation as normal behaviors.
19. **Multiple files.** One window per file, tabs, or a single document at a time? : Sigle document only. But... can run multiple instances.
20. **Large files.** Is there a target file size (e.g. 10 MB, 100 MB) the app must handle smoothly? : At this moment, test with <5MB file first. Progressive load file and rendering will be the future tasks.
21. **Language switch.** Thai/English: follow the OS language, or a setting in Settings, or both? : Add to the toolbar to switch
22. **Windows default app.** On Windows, apps can register as a handler but the user picks the default in Settings. Is "appears in Open with and can be set as default" enough? : Yes, Enough
