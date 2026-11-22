import 'bracket_match.dart';

/// One search match: [start] to [end] (exclusive) on [line], in UTF-16
/// units, as the editor counts them.
typedef SearchMatch = ({int line, int start, int end});

/// A JSON token's text on one line: a string's characters between its
/// quotes, or a bare number / `true` / `false` / `null`.
final _token = RegExp(
  r'"((?:[^"\\]|\\.)*)"?|(-?[0-9][0-9.eE+-]*|true|false|null)',
);

/// Finds [query] in keys and values, never in punctuation or whitespace
/// between tokens (§3.3, #41). Case-insensitive.
///
/// The lines are joined and searched with one regular expression, and only
/// lines with a hit are split into tokens: searching line by line took
/// about 0.8 s at 5 MB (#44).
List<SearchMatch> searchJson(List<String> lines, String query) {
  if (query.isEmpty) return const [];
  final needle = RegExp(RegExp.escape(query), caseSensitive: false);
  final text = lines.join('\n');
  final matches = <SearchMatch>[];
  var line = 0;
  var lineStart = 0;
  var checkedLine = -1;
  for (final hit in needle.allMatches(text)) {
    while (line + 1 < lines.length &&
        lineStart + lines[line].length < hit.start) {
      lineStart += lines[line].length + 1;
      line++;
    }
    if (line == checkedLine) continue; // This line's matches are added.
    checkedLine = line;
    final lineText = lines[line];
    for (final token in _token.allMatches(lineText)) {
      final quoted = token[1] != null;
      final start = quoted ? token.start + 1 : token.start;
      final content = token[1] ?? token[2]!;
      for (final m in needle.allMatches(content)) {
        matches.add((line: line, start: start + m.start, end: start + m.end));
      }
    }
  }
  return matches;
}

/// The match to go to from the caret at [from]: the first one starting
/// after it ([forward]) or before it, wrapping around at the ends. -1 when
/// there are none.
int nextMatch(
  List<SearchMatch> matches,
  TextPoint from, {
  bool forward = true,
}) {
  if (matches.isEmpty) return -1;
  bool after(SearchMatch m) =>
      m.line > from.line || (m.line == from.line && m.start > from.column);
  bool before(SearchMatch m) =>
      m.line < from.line || (m.line == from.line && m.start < from.column);
  if (forward) {
    final i = matches.indexWhere(after);
    return i == -1 ? 0 : i;
  }
  final i = matches.lastIndexWhere(before);
  return i == -1 ? matches.length - 1 : i;
}
