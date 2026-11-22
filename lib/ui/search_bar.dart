import 'package:material_ui/material_ui.dart';
import 'package:re_editor/re_editor.dart';

import '../document/json_search.dart';
import '../l10n/app_localizations.dart';

/// The search field above the Text pane (§3.3, #41): finds the text in keys
/// and values and selects the first match, with a count such as "2 of 7".
class JsonSearchBar extends StatefulWidget {
  const JsonSearchBar({
    super.key,
    required this.controller,
    required this.onClose,
  });

  final CodeLineEditingController controller;
  final VoidCallback onClose;

  @override
  State<JsonSearchBar> createState() => JsonSearchBarState();
}

class JsonSearchBarState extends State<JsonSearchBar> {
  final _query = TextEditingController();
  final _field = FocusNode(debugLabel: 'Search');
  List<SearchMatch> _matches = const [];
  int _current = -1;

  /// Puts the keyboard in the search field and selects its text (Cmd+F
  /// while the bar is already open).
  void focus() {
    _field.requestFocus();
    _query.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _query.text.length,
    );
  }

  @override
  void initState() {
    super.initState();
    _field.requestFocus();
  }

  @override
  void dispose() {
    _query.dispose();
    _field.dispose();
    super.dispose();
  }

  void _search(String query) {
    final controller = widget.controller;
    if (query.isNotEmpty) _unfoldAll(controller);
    final lines = controller.codeLines;
    final matches = searchJson((i) => lines[i].text, lines.length, query);
    setState(() {
      _matches = matches;
      _current = matches.isEmpty ? -1 : 0;
    });
    // No match leaves the selection alone.
    if (matches.isNotEmpty) _select(matches.first);
  }

  void _select(SearchMatch match) {
    widget.controller
      ..selection = CodeLineSelection(
        baseIndex: match.line,
        baseOffset: match.start,
        extentIndex: match.line,
        extentOffset: match.end,
      )
      ..makeCursorVisible();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final status = _query.text.isEmpty
        ? ''
        : _matches.isEmpty
        ? l10n.searchNoResults
        : l10n.searchCount(_current + 1, _matches.length);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: const Key('searchField'),
              controller: _query,
              focusNode: _field,
              onChanged: _search,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 16),
                prefixIconConstraints: const BoxConstraints(minWidth: 28),
                hintText: l10n.searchHint,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            status,
            key: const Key('searchStatus'),
            style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            tooltip: l10n.searchClose,
            onPressed: widget.onClose,
          ),
        ],
      ),
    );
  }
}

/// Search covers folded text too, so folds are opened first (decision #76).
void _unfoldAll(CodeLineEditingController controller) {
  for (var i = controller.codeLines.length - 1; i >= 0; i--) {
    if (controller.codeLines[i].chunkParent) controller.expandChunk(i);
  }
}
