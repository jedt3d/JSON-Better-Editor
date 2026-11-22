import 'package:flutter_test/flutter_test.dart';
import 'package:json_better_editor/document/bracket_match.dart';

List<TextPoint>? at(String text, int line, int column) {
  final lines = text.split('\n');
  return matchAt((i) => lines[i], lines.length, (line: line, column: column));
}

TextPoint p(int line, int column) => (line: line, column: column);

void main() {
  group('brackets', () {
    test('caret after an opening bracket pairs it with its closer', () {
      expect(at('{"a": [1, 2]}', 0, 1), [p(0, 0), p(0, 12)]);
    });

    test('caret after a closing bracket pairs it backwards', () {
      expect(at('{"a": [1, 2]}', 0, 13), [p(0, 12), p(0, 0)]);
      expect(at('{"a": [1, 2]}', 0, 12), [p(0, 11), p(0, 6)]);
    });

    test('the bracket before the caret wins over the one after', () {
      expect(at('[[1]]', 0, 1), [p(0, 0), p(0, 4)]);
    });

    test('nested pairs across lines', () {
      const text = '{\n  "a": [\n    {"b": 1}\n  ]\n}';
      expect(at(text, 1, 8), [p(1, 7), p(3, 2)]);
      expect(at(text, 2, 4), [p(2, 4), p(2, 11)]);
      expect(at(text, 4, 1), [p(4, 0), p(0, 0)]);
    });

    test('brackets inside strings are ignored when scanning', () {
      expect(at('["]", "{", 1]', 0, 1), [p(0, 0), p(0, 12)]);
    });

    test('unbalanced: never closed or never opened gives nothing', () {
      expect(at('{"a": [1, 2}', 0, 6), isNull, reason: '[ closed by }');
      expect(at('{"a": 1', 0, 1), isNull);
      expect(at('"a": 1}', 0, 7), isNull);
    });

    test('no bracket next to the caret gives nothing', () {
      expect(at('{"a": 12}', 0, 7), isNull);
    });
  });

  group('quotes', () {
    test('caret inside a string pairs its two quotes', () {
      expect(at('{"key": "value"}', 0, 3), [p(0, 1), p(0, 5)]);
      expect(at('{"key": "value"}', 0, 14), [p(0, 8), p(0, 14)]);
    });

    test('escaped quotes do not end the string', () {
      expect(at(r'["a\"b"]', 0, 4), [p(0, 1), p(0, 6)]);
    });

    test('a bracket inside a string pairs the quotes, not the bracket', () {
      expect(at('["{"]', 0, 3), [p(0, 1), p(0, 3)]);
    });

    test('an unclosed string gives nothing', () {
      expect(at('{"open', 0, 4), isNull);
    });
  });

  group('multi-line blocks (folding)', () {
    test('one block per opening line, outermost wins', () {
      const text = '[{\n  "a": [\n    1\n  ],\n  "s": "{["\n}]';
      expect(multiLineBlocks(text.split('\n')), [(0, 5), (1, 3)]);
    });

    test('single-line and unbalanced brackets are not blocks', () {
      expect(multiLineBlocks(['{"a": [1, 2]}']), isEmpty);
      expect(multiLineBlocks(['{', '  "a": 1']), isEmpty);
    });
  });

  test('bracketsOutsideStrings skips escaped quotes', () {
    expect(bracketsOutsideStrings(r'{"a\"[": [1]}'), [0, 9, 11, 12]);
  });
}
