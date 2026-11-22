import 'package:re_editor/re_editor.dart';

final _lists = Expando<List<CodeLine>>();

/// The visible lines as a plain list, built once per [CodeLines] object.
/// `CodeLines[i]` and `CodeLines.length` walk all of its segments on every
/// call, which made line-by-line loops quadratic on large files (#44).
List<CodeLine> lineList(CodeLines lines) => _lists[lines] ??= [
  for (final segment in lines.segments) ...segment.codeLines,
];

/// Whether [a] and [b] hold the same text, folded parts included.
bool sameText(CodeLines a, CodeLines b) {
  final left = <String>[];
  final right = <String>[];
  _texts(a, left);
  _texts(b, right);
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    // Unchanged lines are the same String object: a cheap check.
    if (left[i] != right[i]) return false;
  }
  return true;
}

void _texts(CodeLines lines, List<String> out) {
  void add(CodeLine line) {
    out.add(line.text);
    line.chunks.forEach(add);
  }

  for (final segment in lines.segments) {
    segment.codeLines.forEach(add);
  }
}
