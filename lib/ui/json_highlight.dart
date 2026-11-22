import 'package:material_ui/material_ui.dart';
import 'package:re_highlight/re_highlight.dart';

/// Highlight scopes of the JSON grammar (§1.1), one colour each.
abstract final class JsonScope {
  static const key = 'attr';
  static const string = 'string';
  static const number = 'number';
  static const boolean = 'literal';
  static const nullValue = 'keyword';
  static const punctuation = 'punctuation';
}

/// JSON grammar for re_highlight. Unlike the package's own JSON grammar it
/// gives `null` its own colour, has no "illegal" rule (so invalid JSON
/// stays highlighted while typing) and colours an unclosed string up to the
/// end of its line.
final jsonMode = Mode(
  name: 'JSON',
  contains: <Mode>[
    Mode(scope: JsonScope.key, match: r'"(?:\\.|[^\\"\r\n])*"(?=\s*:)'),
    Mode(scope: JsonScope.string, match: r'"(?:\\.|[^\\"\r\n])*"?'),
    Mode(scope: JsonScope.punctuation, match: r'[{}\[\],:]'),
    Mode(scope: JsonScope.boolean, match: r'\b(?:true|false)\b'),
    Mode(scope: JsonScope.nullValue, match: r'\bnull\b'),
    Mode(
      scope: JsonScope.number,
      match: r'-?\b\d+(?:\.\d+)?(?:[eE][+-]?\d+)?\b',
    ),
  ],
);

/// Basic light and dark token colours (One Light / One Dark come in
/// Phase 4). String green and Number blue match the Node pane's type colours
/// (§2.2).
Map<String, TextStyle> jsonHighlightTheme(ColorScheme colors) {
  final dark = colors.brightness == Brightness.dark;
  Color pick(int light, int night) => Color(dark ? night : light);
  return {
    JsonScope.key: TextStyle(color: pick(0xFF8E24AA, 0xFFCE93D8)),
    JsonScope.string: TextStyle(color: pick(0xFF2E7D32, 0xFFA5D6A7)),
    JsonScope.number: TextStyle(color: pick(0xFF1565C0, 0xFF90CAF9)),
    JsonScope.boolean: TextStyle(color: pick(0xFFE65100, 0xFFFFCC80)),
    JsonScope.nullValue: TextStyle(color: pick(0xFFC62828, 0xFFEF9A9A)),
    JsonScope.punctuation: TextStyle(color: colors.onSurfaceVariant),
  };
}
