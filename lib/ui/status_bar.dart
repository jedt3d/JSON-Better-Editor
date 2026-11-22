import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:re_editor/re_editor.dart';

import '../document/json_document.dart';
import '../l10n/app_localizations.dart';
import 'line_list.dart';

/// The Status Bar along the bottom of the window (§3.12, decision #88).
/// Left to right: pane label · (JSON status, caret: #99, #100) ······
/// (toggles and actions: #102, #103) ······ (line endings: #104) · document
/// size. Its height comes from the text style, never fixed pixels.
class StatusBar extends StatefulWidget {
  const StatusBar({
    super.key,
    required this.controller,
    this.check,
    this.onValidate,
    this.onGoToLine,
    this.onShowErrors,
  });

  /// The open document's editor, or null when nothing is open.
  final CodeLineEditingController? controller;

  /// The last check of the text (Validate JSON, Open or Save), shown as the
  /// JSON status (#99). There is no live validation (decision #87).
  final JsonCheck? check;

  /// Runs Validate JSON; called when the status says the text changed since
  /// the last check.
  final VoidCallback? onValidate;

  /// Opens Go to Line; called when the caret position is clicked (#100).
  final VoidCallback? onGoToLine;

  /// Opens the error list above the JSON status item, given that item's
  /// context to anchor on (#101).
  final void Function(BuildContext anchor)? onShowErrors;

  @override
  State<StatusBar> createState() => _StatusBarState();
}

class _StatusBarState extends State<StatusBar> {
  /// Whether the text changed since [StatusBar.check]. Once changed it stays
  /// changed until a new check, except that undo back to the checked text
  /// brings back the checked lines object itself.
  bool _changedSinceCheck = false;

  bool _computeChanged() {
    final check = widget.check;
    final lines = widget.controller?.codeLines;
    if (check == null || lines == null || identical(lines, check.lines)) {
      return false;
    }
    return _changedSinceCheck || !sameText(lines, check.lines);
  }

  void _updateCheckState() {
    final changed = _computeChanged();
    if (changed != _changedSinceCheck) {
      setState(() => _changedSinceCheck = changed);
    }
  }

  /// `Ln L, Col C` and `(N selected)` (#100); both 1-based, logical lines
  /// (folded lines counted), columns in characters.
  String _caret = '';

  void _updateCaret() {
    final controller = widget.controller;
    var caret = '';
    if (controller != null) {
      final l10n = AppLocalizations.of(context)!;
      final selection = controller.selection;
      final line = controller.index2lineIndex(selection.extentIndex) + 1;
      final text = lineList(controller.codeLines)[selection.extentIndex].text;
      final column =
          text
              .substring(0, selection.extentOffset.clamp(0, text.length))
              .runes
              .length +
          1;
      caret = l10n.statusCaret(line, column);
      if (!selection.isCollapsed) {
        // ponytail: builds the selected text to count it; slow for a huge
        // selection (Cmd+A on 20 MB), Phase 5 (#82).
        caret = l10n.statusCaretSelected(
          caret,
          controller.selectedText.runes.length,
        );
      }
    }
    if (caret != _caret) setState(() => _caret = caret);
  }

  int _lines = 0;
  int _bytes = 0;
  Timer? _debounce;
  CodeLines? _counted;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onChanged);
    _count();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateCaret();
    });
  }

  @override
  void didUpdateWidget(StatusBar old) {
    super.didUpdateWidget(old);
    if (!identical(old.controller, widget.controller)) {
      old.controller?.removeListener(_onChanged);
      widget.controller?.addListener(_onChanged);
      _count();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateCaret();
      });
    }
    if (!identical(old.check, widget.check)) {
      _changedSinceCheck = false;
      _changedSinceCheck = _computeChanged();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller?.removeListener(_onChanged);
    super.dispose();
  }

  // ponytail: counts the whole text 250 ms after the last change (about
  // 20 ms at 20 MB); keep running totals per line if Phase 5 needs it.
  void _onChanged() {
    _updateCheckState();
    _updateCaret();
    if (identical(widget.controller?.codeLines, _counted)) return; // Caret.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _count);
  }

  void _count() {
    final lines = widget.controller?.codeLines;
    _counted = lines;
    var count = 0;
    var bytes = 0;
    void add(CodeLine line) {
      count++;
      bytes += _utf8Length(line.text) + 1; // + the line break.
      line.chunks.forEach(add); // Folded lines.
    }

    if (lines != null) {
      lineList(lines).forEach(add);
      bytes -= 1; // No break after the last line.
    }
    if (mounted) {
      setState(() {
        _lines = count;
        _bytes = lines == null ? 0 : bytes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final hasDocument = widget.controller != null;
    return Container(
      key: const Key('statusBar'),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: DefaultTextStyle.merge(
        style: style,
        // A narrow window cuts the left items off instead of overflowing.
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Row(
                  children: [
                    Text(l10n.statusPaneText, key: const Key('statusPane')),
                    if (hasDocument && widget.check != null) ...[
                      const SizedBox(width: 16),
                      _jsonStatus(l10n, theme),
                    ],
                    if (hasDocument && _caret.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      _StatusButton(
                        key: const Key('caretPosition'),
                        label: _caret,
                        color: theme.colorScheme.onSurfaceVariant,
                        tooltip: l10n.goToLineTitle,
                        onPressed: widget.onGoToLine,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            if (hasDocument)
              Text(
                l10n.statusSize(_lines, formatSize(_bytes)),
                key: const Key('statusSize'),
              ),
          ],
        ),
      ),
    );
  }
}

/// The JSON status item (#99).
extension on _StatusBarState {
  Widget _jsonStatus(AppLocalizations l10n, ThemeData theme) {
    final check = widget.check!;
    final colors = theme.colorScheme;
    if (_changedSinceCheck) {
      return _StatusButton(
        key: const Key('jsonStatus'),
        label: l10n.statusNotChecked,
        color: colors.onSurfaceVariant.withValues(alpha: 0.7),
        tooltip: l10n.statusValidateTooltip,
        onPressed: widget.onValidate,
      );
    }
    final errors = check.errors.length;
    if (errors == 0) {
      return _StatusButton(
        key: const Key('jsonStatus'),
        label: l10n.statusValid,
        color: colors.primary,
      );
    }
    return Builder(
      builder: (anchor) => _StatusButton(
        key: const Key('jsonStatus'),
        label: l10n.statusInvalid(errors),
        color: colors.error,
        tooltip: l10n.statusShowErrorsTooltip,
        onPressed: widget.onShowErrors == null
            ? null
            : () => widget.onShowErrors!(anchor),
      ),
    );
  }
}

/// A small text button in the Status Bar.
class _StatusButton extends StatelessWidget {
  const _StatusButton({
    super.key,
    required this.label,
    required this.color,
    this.tooltip,
    this.onPressed,
  });

  final String label;
  final Color color;
  final String? tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final text = Text(label, style: TextStyle(color: color));
    if (onPressed == null) return text;
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: text,
        ),
      ),
    );
  }
}

/// The result of checking the text once: the lines checked and the errors
/// found (empty when valid).
class JsonCheck {
  const JsonCheck(this.lines, this.errors);

  final CodeLines lines;
  final List<JsonParseError> errors;
}

/// Bytes of [text] in UTF-8, without building the encoded copy.
int _utf8Length(String text) {
  var bytes = 0;
  for (final rune in text.runes) {
    bytes += rune < 0x80
        ? 1
        : rune < 0x800
        ? 2
        : rune < 0x10000
        ? 3
        : 4;
  }
  return bytes;
}

/// `S KB` in the Status Bar: bytes under 1 KB, then KB, then MB, with one
/// decimal below 10.
String formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb < 10 ? kb.toStringAsFixed(1) : kb.round()} KB';
  final mb = kb / 1024;
  return '${mb < 10 ? mb.toStringAsFixed(1) : mb.round()} MB';
}
