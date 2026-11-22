import 'package:material_ui/material_ui.dart';
import 'package:re_editor/re_editor.dart';

import '../document/bracket_match.dart';

/// A quote typed where an object key goes: after `{` or `,` (or at the
/// start of a line), with the key's first characters after it.
final _keyStart = RegExp(r'(?:^|[{,])\s*"((?:[^"\\]|\\.)*)$');

/// Keys on one line: a quoted string followed by `:`.
final _keyOnLine = RegExp(r'"((?:[^"\\]|\\.)*)"\s*:');

/// Suggests keys that already exist in the document while a key is typed
/// in an object (§1.3, #40).
class JsonKeyPrompts implements CodeAutocompletePromptsBuilder {
  JsonKeyPrompts(this.controller);

  final CodeLineEditingController controller;

  /// Keys found on each line, kept per line object: re_editor replaces only
  /// the edited lines, so a keystroke rescans one line, not the document.
  final _keysOfLine = Expando<List<String>>();

  @override
  CodeAutocompleteEditingValue? build(
    BuildContext context,
    CodeLine codeLine,
    CodeLineSelection selection,
  ) {
    final before = codeLine.text.substring(0, selection.extentOffset);
    final typed = _keyStart.firstMatch(before);
    if (typed == null) return null;
    final input = typed[1]!;
    final lines = controller.codeLines;
    final container = openContainerAt((i) => lines[i].text, (
      line: selection.extentIndex,
      column: selection.extentOffset,
    ));
    if (container != '{') return null; // In an array, or outside any value.

    final closed = codeLine.text
        .substring(selection.extentOffset)
        .startsWith('"');
    final keys = _documentKeys(
      lines,
    ).where((key) => key != input && key.startsWith(input));
    final prompts = [
      for (final key in keys)
        CodeFieldPrompt(
          word: key,
          type: '',
          // Closes the key's quote unless one is already there.
          customAutocomplete: CodeAutocompleteResult.fromWord(
            closed ? key : '$key"',
          ),
        ),
    ];
    if (prompts.isEmpty) return null;
    return CodeAutocompleteEditingValue(
      input: input,
      prompts: prompts,
      index: 0,
    );
  }

  // ponytail: walks every line on each keystroke in a key position (cached
  // per line, so only identity lookups); #44 checks the cost on 5 MB.
  List<String> _documentKeys(CodeLines lines) {
    final keys = <String>{};
    void add(CodeLine line) {
      keys.addAll(
        _keysOfLine[line] ??= [
          for (final m in _keyOnLine.allMatches(line.text)) m[1]!,
        ],
      );
      line.chunks.forEach(add); // Folded lines (#36).
    }

    for (final segment in lines.segments) {
      segment.codeLines.forEach(add);
    }
    return keys.toList()..sort();
  }
}

/// The suggestion list under the caret. Up/Down move, Enter accepts, a
/// click accepts.
class KeySuggestions extends StatelessWidget implements PreferredSizeWidget {
  const KeySuggestions({
    super.key,
    required this.notifier,
    required this.onSelected,
  });

  final ValueNotifier<CodeAutocompleteEditingValue> notifier;
  final ValueChanged<CodeAutocompleteResult> onSelected;

  static const _rowHeight = 24.0;
  static const _maxRows = 8;

  @override
  Size get preferredSize => const Size(260, _rowHeight * _maxRows + 8);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ValueListenableBuilder(
      valueListenable: notifier,
      // material_ui's Material, for the InkWells (re_editor wraps the popup
      // in package:flutter/material's).
      builder: (context, value, _) => Material(
        type: MaterialType.transparency,
        child: Container(
          key: const Key('keySuggestions'),
          constraints: BoxConstraints.loose(preferredSize),
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: colors.outlineVariant),
            boxShadow: const [
              BoxShadow(blurRadius: 8, color: Color(0x33000000)),
            ],
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemExtent: _rowHeight,
            itemCount: value.prompts.length,
            itemBuilder: (context, i) {
              final selected = i == value.index;
              return InkWell(
                onTap: () => onSelected(value.copyWith(index: i).autocomplete),
                child: Container(
                  color: selected ? colors.primaryContainer : null,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value.prompts[i].word,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Menlo',
                      fontSize: 13,
                      color: selected
                          ? colors.onPrimaryContainer
                          : colors.onSurface,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
