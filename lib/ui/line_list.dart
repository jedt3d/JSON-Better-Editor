import 'package:re_editor/re_editor.dart';

final _lists = Expando<List<CodeLine>>();

/// The visible lines as a plain list, built once per [CodeLines] object.
/// `CodeLines[i]` and `CodeLines.length` walk all of its segments on every
/// call, which made line-by-line loops quadratic on large files (#44).
List<CodeLine> lineList(CodeLines lines) => _lists[lines] ??= [
  for (final segment in lines.segments) ...segment.codeLines,
];
