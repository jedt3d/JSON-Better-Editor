import 'package:material_ui/material_ui.dart';
import 'package:re_editor/re_editor.dart';

/// Indent unit for Tab, Shift+Tab and Save's pretty-print (decision #57).
const indentSize = 2;

/// A controller holding [text], set up for JSON editing.
CodeLineEditingController textPaneController(String text) =>
    CodeLineEditingController.fromText(
      text,
      const CodeLineOptions(indentSize: indentSize),
    );

/// The editable Text pane (decision #60: built on re_editor).
class TextPane extends StatelessWidget {
  const TextPane({super.key, required this.controller});

  final CodeLineEditingController controller;

  @override
  Widget build(BuildContext context) {
    // re_editor reads package:flutter/material themes, not material_ui's, so
    // every colour is passed in explicitly.
    final colors = Theme.of(context).colorScheme;
    return CodeEditor(
      controller: controller,
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
