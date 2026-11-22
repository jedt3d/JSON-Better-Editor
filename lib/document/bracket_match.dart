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

// ponytail: pairing the root bracket of a large file walks the whole file
// (about 30 ms at 5 MB, #44). Cap the walk if that ever shows as lag.
TextPoint? _scanForward(
  String Function(int) lineAt,
  int lineCount,
  TextPoint from,
) {
  final stack = <int>[];
  for (var line = from.line; line < lineCount; line++) {
    for (final i in bracketsOutsideStrings(lineAt(line))) {
      if (line == from.line && i < from.column) continue;
      final c = lineAt(line).codeUnitAt(i);
      if (_isOpen(c)) {
        stack.add(c);
      } else {
        if (stack.isEmpty || !_pairs(stack.removeLast(), c)) return null;
        if (stack.isEmpty) return (line: line, column: i);
      }
    }
  }
  return null; // Never closed.
}

TextPoint? _scanBackward(String Function(int) lineAt, TextPoint from) {
  final stack = <int>[];
  for (var line = from.line; line >= 0; line--) {
    final text = lineAt(line);
    for (final i in bracketsOutsideStrings(text).reversed) {
      if (line == from.line && i > from.column) continue;
      final c = text.codeUnitAt(i);
      if (!_isOpen(c)) {
        stack.add(c);
      } else {
        if (stack.isEmpty || !_pairs(c, stack.removeLast())) return null;
        if (stack.isEmpty) return (line: line, column: i);
      }
    }
  }
  return null;
}

const _quote = 0x22, _backslash = 0x5C;
const _openBrace = 0x7B, _closeBrace = 0x7D;
const _openBracket = 0x5B, _closeBracket = 0x5D;

bool _isOpen(int c) => c == _openBrace || c == _openBracket;

bool _pairs(int open, int close) =>
    (open == _openBrace && close == _closeBrace) ||
    (open == _openBracket && close == _closeBracket);

/// Columns of `{ } [ ]` on one line that are not inside a string. JSON
/// strings never span lines, so each line is read on its own.
List<int> bracketsOutsideStrings(String text) {
  final columns = <int>[];
  var inString = false;
  for (var i = 0; i < text.length; i++) {
    final c = text.codeUnitAt(i);
    if (inString) {
      if (c == _backslash) {
        i++;
      } else if (c == _quote) {
        inString = false;
      }
    } else if (c == _quote) {
      inString = true;
    } else if (c == _openBrace ||
        c == _closeBrace ||
        c == _openBracket ||
        c == _closeBracket) {
      columns.add(i);
    }
  }
  return columns;
}

/// Blocks that span more than one line, as (opening line, closing line),
/// one per opening line (the outermost when several open on one line).
/// Unbalanced brackets are skipped. Used for folding (#36).
List<(int, int)> multiLineBlocks(List<String> lines) {
  final open = <(int, int)>[]; // (bracket, line)
  final byStart = <int, int>{};
  for (var line = 0; line < lines.length; line++) {
    final text = lines[line];
    for (final i in bracketsOutsideStrings(text)) {
      final c = text.codeUnitAt(i);
      if (_isOpen(c)) {
        open.add((c, line));
      } else if (open.isNotEmpty && _pairs(open.last.$1, c)) {
        final start = open.removeLast().$2;
        if (line > start) byStart[start] = line;
      }
    }
  }
  return [for (final e in byStart.entries) (e.key, e.value)]
    ..sort((a, b) => a.$1 - b.$1);
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
    for (final i in bracketsOutsideStrings(text).reversed) {
      if (line == caret.line && i >= caret.column) continue;
      if (!_isOpen(text.codeUnitAt(i))) {
        depth++;
      } else if (depth == 0) {
        return text[i];
      } else {
        depth--;
      }
    }
  }
  return null;
}
