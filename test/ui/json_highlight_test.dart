import 'package:flutter_test/flutter_test.dart';
import 'package:json_better_editor/ui/json_highlight.dart';
import 'package:material_ui/material_ui.dart';
import 'package:re_highlight/re_highlight.dart';

/// Collects (scope, text) for every highlighted token.
class _Tokens implements HighlightRenderer {
  final tokens = <(String, String)>[];
  final _open = <String?>[];

  @override
  void addText(String text) {
    final scope = _open.lastWhere((s) => s != null, orElse: () => null);
    if (scope != null) tokens.add((scope, text));
  }

  @override
  void openNode(DataNode node) => _open.add(node.scope);

  @override
  void closeNode(DataNode node) => _open.removeLast();
}

List<(String, String)> tokensOf(String code) {
  final highlight = Highlight()..registerLanguage('json', jsonMode);
  final renderer = _Tokens();
  highlight.highlight(code: code, language: 'json').render(renderer);
  return renderer.tokens;
}

void main() {
  test('keys, strings, numbers, booleans, null and punctuation', () {
    expect(
      tokensOf('{"a": "x", "n": -1.5e3, "t": true, "f": false, "z": null}'),
      [
        (JsonScope.punctuation, '{'),
        (JsonScope.key, '"a"'),
        (JsonScope.punctuation, ':'),
        (JsonScope.string, '"x"'),
        (JsonScope.punctuation, ','),
        (JsonScope.key, '"n"'),
        (JsonScope.punctuation, ':'),
        (JsonScope.number, '-1.5e3'),
        (JsonScope.punctuation, ','),
        (JsonScope.key, '"t"'),
        (JsonScope.punctuation, ':'),
        (JsonScope.boolean, 'true'),
        (JsonScope.punctuation, ','),
        (JsonScope.key, '"f"'),
        (JsonScope.punctuation, ':'),
        (JsonScope.boolean, 'false'),
        (JsonScope.punctuation, ','),
        (JsonScope.key, '"z"'),
        (JsonScope.punctuation, ':'),
        (JsonScope.nullValue, 'null'),
        (JsonScope.punctuation, '}'),
      ],
    );
  });

  test('a string in an array is a value, not a key', () {
    expect(tokensOf('["a", "b"]'), [
      (JsonScope.punctuation, '['),
      (JsonScope.string, '"a"'),
      (JsonScope.punctuation, ','),
      (JsonScope.string, '"b"'),
      (JsonScope.punctuation, ']'),
    ]);
  });

  test('escaped quotes stay inside the string', () {
    expect(tokensOf(r'{"k\"q": "v\"w"}'), contains((JsonScope.key, r'"k\"q"')));
    expect(
      tokensOf(r'{"k\"q": "v\"w"}'),
      contains((JsonScope.string, r'"v\"w"')),
    );
  });

  test('invalid JSON while typing is still highlighted', () {
    final tokens = tokensOf('{"a": tru, "b": 1,, "c": "open\n  "d": 2}');
    expect(tokens, contains((JsonScope.key, '"a"')));
    expect(tokens, contains((JsonScope.number, '1')));
    expect(tokens, contains((JsonScope.string, '"open')), reason: 'unclosed');
    expect(tokens, contains((JsonScope.key, '"d"')), reason: 'next line ok');
    expect(tokens, contains((JsonScope.number, '2')));
  });

  test('every scope has its own colour, in light and dark', () {
    for (final brightness in Brightness.values) {
      final theme = jsonHighlightTheme(
        ColorScheme.fromSeed(seedColor: Colors.blue, brightness: brightness),
      );
      final colours = [
        for (final scope in [
          JsonScope.key,
          JsonScope.string,
          JsonScope.number,
          JsonScope.boolean,
          JsonScope.nullValue,
          JsonScope.punctuation,
        ])
          theme[scope]!.color,
      ];
      expect(colours.toSet(), hasLength(6), reason: '$brightness');
    }
  });
}
