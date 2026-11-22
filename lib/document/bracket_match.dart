/// A place in the text: 0-based line and column (UTF-16 units, as in the
/// editor).
typedef TextPoint = ({int line, int column});

const _open = '{[';
const _close = '}]';

/// What to highlight for the caret at [caret] (§1.1, #35):
/// - inside a string: its two quotes;
/// - next to a bracket (`{ } [ ]`, the one before the caret first): the
///   bracket and its partner.
/// Null when there is nothing to pair: no bracket or string at the caret,
/// an unclosed string, or an unbalanced or mismatched bracket. Brackets
/// inside strings are ignored.
List<TextPoint>? matchAt(
  String Function(int line) lineAt,
  int lineCount,
  TextPoint caret,
) {
  final text = lineAt(caret.line);
  final strings = _stringRanges(text);
  for (final (open, close) in strings) {
    if (open < caret.column && caret.column <= close) {
      return close < text.length && text[close] == '"'
          ? [
              (line: caret.line, column: open),
              (line: caret.line, column: close),
            ]
          : null; // Unclosed string.
    }
  }
  for (final column in [caret.column - 1, caret.column]) {
    if (column < 0 || column >= text.length) continue;
    final c = text[column];
    if (!_open.contains(c) && !_close.contains(c)) continue;
    if (_inString(strings, column)) continue;
    final at = (line: caret.line, column: column);
    final partner = _open.contains(c)
        ? _scanForward(lineAt, lineCount, at)
        : _scanBackward(lineAt, at);
    return partner == null ? null : [at, partner];
  }
  return null;
}

// ponytail: scans line by line from the bracket, so pairing the root `{`
// of a huge file walks the whole file (a few ms per MB). Cap the scan if
// #44 shows caret moves lagging.
TextPoint? _scanForward(
  String Function(int) lineAt,
  int lineCount,
  TextPoint from,
) {
  final stack = <String>[];
  for (var line = from.line; line < lineCount; line++) {
    final text = lineAt(line);
    final strings = _stringRanges(text);
    final start = line == from.line ? from.column : 0;
    for (var i = start; i < text.length; i++) {
      final c = text[i];
      if (_inString(strings, i)) continue;
      if (_open.contains(c)) {
        stack.add(c);
      } else if (_close.contains(c)) {
        if (stack.isEmpty ||
            _open.indexOf(stack.removeLast()) != _close.indexOf(c)) {
          return null; // Mismatched.
        }
        if (stack.isEmpty) return (line: line, column: i);
      }
    }
  }
  return null; // Never closed.
}

TextPoint? _scanBackward(String Function(int) lineAt, TextPoint from) {
  final stack = <String>[];
  for (var line = from.line; line >= 0; line--) {
    final text = lineAt(line);
    final strings = _stringRanges(text);
    final start = line == from.line ? from.column : text.length - 1;
    for (var i = start; i >= 0; i--) {
      final c = text[i];
      if (_inString(strings, i)) continue;
      if (_close.contains(c)) {
        stack.add(c);
      } else if (_open.contains(c)) {
        if (stack.isEmpty ||
            _close.indexOf(stack.removeLast()) != _open.indexOf(c)) {
          return null;
        }
        if (stack.isEmpty) return (line: line, column: i);
      }
    }
  }
  return null;
}

/// (opening quote, closing quote) of each string on one line. An unclosed
/// string ends at the line's length. JSON strings never span lines.
List<(int, int)> _stringRanges(String text) {
  final ranges = <(int, int)>[];
  var i = 0;
  while (i < text.length) {
    if (text[i] != '"') {
      i++;
      continue;
    }
    final open = i++;
    while (i < text.length && text[i] != '"') {
      i += text[i] == r'\' ? 2 : 1;
    }
    final close = i < text.length ? i : text.length;
    ranges.add((open, close));
    i = close + 1;
  }
  return ranges;
}

bool _inString(List<(int, int)> strings, int i) =>
    strings.any((r) => r.$1 <= i && i <= r.$2);

/// The innermost `{` or `[` that is still open at [caret], or null at the
/// top level. Used to tell a key position (inside an object) from a value
/// in an array.
String? openContainerAt(String Function(int line) lineAt, TextPoint caret) {
  var depth = 0;
  for (var line = caret.line; line >= 0; line--) {
    final text = lineAt(line);
    final strings = _stringRanges(text);
    final start = line == caret.line ? caret.column - 1 : text.length - 1;
    for (var i = start; i >= 0; i--) {
      final c = text[i];
      if (_inString(strings, i)) continue;
      if (_close.contains(c)) {
        depth++;
      } else if (_open.contains(c)) {
        if (depth == 0) return c;
        depth--;
      }
    }
  }
  return null;
}
