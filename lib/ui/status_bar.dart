import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:re_editor/re_editor.dart';

import '../l10n/app_localizations.dart';
import 'line_list.dart';

/// The Status Bar along the bottom of the window (§3.12, decision #88).
/// Left to right: pane label · (JSON status, caret: #99, #100) ······
/// (toggles and actions: #102, #103) ······ (line endings: #104) · document
/// size. Its height comes from the text style, never fixed pixels.
class StatusBar extends StatefulWidget {
  const StatusBar({super.key, required this.controller});

  /// The open document's editor, or null when nothing is open.
  final CodeLineEditingController? controller;

  @override
  State<StatusBar> createState() => _StatusBarState();
}

class _StatusBarState extends State<StatusBar> {
  int _lines = 0;
  int _bytes = 0;
  Timer? _debounce;
  CodeLines? _counted;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onChanged);
    _count();
  }

  @override
  void didUpdateWidget(StatusBar old) {
    super.didUpdateWidget(old);
    if (!identical(old.controller, widget.controller)) {
      old.controller?.removeListener(_onChanged);
      widget.controller?.addListener(_onChanged);
      _count();
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
        child: Row(
          children: [
            Text(l10n.statusPaneText, key: const Key('statusPane')),
            const Spacer(),
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
