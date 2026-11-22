import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:re_editor/re_editor.dart';

import '../document/bracket_match.dart';
import 'json_highlight.dart';
import 'key_autocomplete.dart';

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
  const TextPane({super.key, required this.controller, this.wordWrap = false});

  final CodeLineEditingController controller;

  /// Long lines wrap to the pane's width (#39); line numbers still count
  /// logical lines.
  final bool wordWrap;

  @override
  State<TextPane> createState() => _TextPaneState();
}

class _TextPaneState extends State<TextPane> {
  final _focus = FocusNode(debugLabel: 'TextPane');
  late final _keyPrompts = JsonKeyPrompts(widget.controller);

  /// Esc closes the key suggestions (#40). re_editor has no call for that;
  /// it closes them whenever the caret moves without a text change, so the
  /// caret is moved off and back. Harmless when no list is shown.
  void _closeSuggestions() {
    final controller = widget.controller;
    final selection = controller.selection;
    // A list needs a typed quote, so the caret is never at column 0 then.
    if (selection.extentOffset == 0) return;
    controller.selection = CodeLineSelection.collapsed(
      index: selection.extentIndex,
      offset: 0,
    );
    controller.selection = selection;
  }

  /// Bracket or quote pair at the caret (#35), recomputed when the text or
  /// the caret changes, not on every scroll.
  final _pair = ValueNotifier<List<TextPoint>?>(null);

  /// The visible lines and their positions, from re_editor's gutter; it
  /// changes on scroll, and [_linesChanged] tells the pair painter.
  CodeIndicatorValueNotifier? _visibleLines;
  final _linesChanged = ValueNotifier(0);

  void _onLines() => _linesChanged.value++;

  void _watchLines(CodeIndicatorValueNotifier notifier) {
    if (identical(notifier, _visibleLines)) return;
    _visibleLines?.removeListener(_onLines);
    _visibleLines = notifier..addListener(_onLines);
  }

  final _gutterKey = GlobalKey();

  void _updatePair() {
    final controller = widget.controller;
    final lines = controller.codeLines;
    final selection = controller.selection;
    _pair.value = selection.isCollapsed
        ? matchAt((i) => lines[i].text, lines.length, (
            line: selection.extentIndex,
            column: selection.extentOffset,
          ))
        : null;
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updatePair);
    _updatePair();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updatePair);
    _visibleLines?.removeListener(_onLines);
    _linesChanged.dispose();
    _pair.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // re_editor reads package:flutter/material themes, not material_ui's, so
    // every colour is passed in explicitly.
    final colors = Theme.of(context).colorScheme;
    final editor = CodeEditor(
      controller: widget.controller,
      focusNode: _focus,
      // Auto-closing quotes and brackets doubled them when typing `"x"` in
      // the real app (decision #65).
      autocompleteSymbols: false,
      wordWrap: widget.wordWrap,
      shortcutsActivatorsBuilder: const _TextPaneShortcuts(),
      chunkAnalyzer: const _JsonChunkAnalyzer(),
      // Line numbers (#34): the gutter widens with the number of lines;
      // the caret's line number is drawn in full colour, the others at half.
      indicatorBuilder: (context, editing, chunks, notifier) {
        _watchLines(notifier);
        return Padding(
          key: _gutterKey,
          padding: const EdgeInsets.only(left: 8, right: 4),
          child: Row(
            children: [
              DefaultCodeLineNumber(controller: editing, notifier: notifier),
              // Fold markers on lines that open a multi-line { or [ (#36).
              DefaultCodeChunkIndicator(
                width: 16,
                controller: chunks,
                notifier: notifier,
              ),
            ],
          ),
        );
      },
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
    // Bracket and quote matching (#35) is painted over the text: re_editor
    // has no hook to style single characters by caret position.
    return Stack(
      children: [
        CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): _closeSuggestions,
          },
          // Keys typed in an object get suggestions from the document's
          // keys; Enter accepts, Tab still indents (#40).
          child: CodeAutocomplete(
            promptsBuilder: _keyPrompts,
            viewBuilder: (context, notifier, onSelected) =>
                KeySuggestions(notifier: notifier, onSelected: onSelected),
            child: editor,
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              key: const Key('pairHighlight'),
              painter: _PairPainter(
                pair: _pair,
                visibleLines: () => _visibleLines,
                gutterWidth: () =>
                    (_gutterKey.currentContext?.findRenderObject()
                            as RenderBox?)
                        ?.size
                        .width,
                color: colors.tertiary.withValues(alpha: 0.25),
                border: colors.tertiary.withValues(alpha: 0.7),
                repaint: Listenable.merge([_pair, _linesChanged]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Boxes around the matched bracket or quote pair.
class _PairPainter extends CustomPainter {
  _PairPainter({
    required this.pair,
    required this.visibleLines,
    required this.gutterWidth,
    required this.color,
    required this.border,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final ValueNotifier<List<TextPoint>?> pair;
  final CodeIndicatorValueNotifier? Function() visibleLines;
  final double? Function() gutterWidth;
  final Color color;
  final Color border;

  @override
  void paint(Canvas canvas, Size size) {
    final points = pair.value;
    final lines = visibleLines()?.value?.paragraphs;
    final left = gutterWidth();
    if (points == null || lines == null || left == null) return;
    canvas.clipRect(Rect.fromLTRB(left, 0, size.width, size.height));
    final fill = Paint()..color = color;
    final stroke = Paint()
      ..color = border
      ..style = PaintingStyle.stroke;
    for (final point in points) {
      for (final line in lines) {
        if (line.index != point.line) continue;
        final rects = line.getRangeRects(
          TextRange(start: point.column, end: point.column + 1),
        );
        for (final rect in rects) {
          final box = RRect.fromRectAndRadius(
            rect.shift(line.offset + Offset(left, 0)),
            const Radius.circular(2),
          );
          canvas
            ..drawRRect(box, fill)
            ..drawRRect(box, stroke);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_PairPainter old) =>
      old.color != color || old.border != border;
}

/// Foldable blocks: every multi-line `{ }` or `[ ]` (#36). re_editor keeps
/// the closing line visible after folding; when that line holds only the
/// closing bracket (and a comma), it is folded too, so the block shows as
/// one line ending in the `…` marker.
class _JsonChunkAnalyzer implements CodeChunkAnalyzer {
  const _JsonChunkAnalyzer();

  static final _closerOnly = RegExp(r'^\s*[}\]],?\s*$');

  @override
  List<CodeChunk> run(CodeLines codeLines) => [
    for (final chunk in const DefaultCodeChunkAnalyzer().run(codeLines))
      _closerOnly.hasMatch(codeLines[chunk.end].text)
          ? CodeChunk(chunk.index, chunk.end + 1)
          : chunk,
  ];
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
