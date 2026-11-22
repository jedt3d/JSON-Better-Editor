import 'package:material_ui/material_ui.dart';
import 'package:re_editor/re_editor.dart';

import 'json_highlight.dart';

/// Indent unit for Tab, Shift+Tab and Save's pretty-print (decision #57).
const indentSize = 2;

/// A controller holding [text], set up for JSON editing.
CodeLineEditingController textPaneController(String text) =>
    CodeLineEditingController.fromText(
      text,
      const CodeLineOptions(indentSize: indentSize),
    );

/// The editable Text pane (decision #60: built on re_editor). It takes the
/// keyboard focus when it appears, so typing works right after New or Open
/// (decision #64).
class TextPane extends StatefulWidget {
  const TextPane({super.key, required this.controller});

  final CodeLineEditingController controller;

  @override
  State<TextPane> createState() => _TextPaneState();
}

class _TextPaneState extends State<TextPane> {
  final _focus = FocusNode(debugLabel: 'TextPane');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // re_editor reads package:flutter/material themes, not material_ui's, so
    // every colour is passed in explicitly.
    final colors = Theme.of(context).colorScheme;
    return CodeEditor(
      controller: widget.controller,
      focusNode: _focus,
      // Auto-closing quotes and brackets doubled them when typing `"x"` in
      // the real app (decision #65).
      autocompleteSymbols: false,
      wordWrap: false,
      shortcutsActivatorsBuilder: const _TextPaneShortcuts(),
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      style: CodeEditorStyle(
        // macOS default monospace font (decisions #17, #29).
        fontFamily: 'Menlo',
        fontFamilyFallback: const ['Monaco', 'Courier'],
        fontSize: 13,
        textColor: colors.onSurface,
        backgroundColor: colors.surface,
        cursorColor: colors.primary,
        selectionColor: colors.primary.withValues(alpha: 0.3),
        highlightColor: colors.tertiary.withValues(alpha: 0.3),
        cursorLineColor: colors.onSurface.withValues(alpha: 0.04),
        codeTheme: CodeHighlightTheme(
          languages: {
            'json': CodeHighlightThemeMode(
              mode: jsonMode,
              // ponytail: 4 MB default would switch highlighting off before
              // the 5 MB target (decision #59); #44 measures the cost.
              maxSize: 64 << 20,
            ),
          },
          theme: jsonHighlightTheme(colors),
        ),
      ),
    );
  }
}

/// re_editor's macOS shortcuts, minus the ones the app owns (Save goes to
/// the window, search comes in #41) or that JSON has no use for (comments).
class _TextPaneShortcuts extends DefaultCodeShortcutsActivatorsBuilder {
  const _TextPaneShortcuts();

  static const _notHandledHere = {
    CodeShortcutType.save,
    CodeShortcutType.find,
    CodeShortcutType.findToggleMatchCase,
    CodeShortcutType.findToggleRegex,
    CodeShortcutType.replace,
    CodeShortcutType.singleLineComment,
    CodeShortcutType.multiLineComment,
  };

  @override
  List<ShortcutActivator>? build(CodeShortcutType type) =>
      _notHandledHere.contains(type) ? null : super.build(type);
}
