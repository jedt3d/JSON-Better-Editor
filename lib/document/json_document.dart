import 'dart:convert';

/// A JSON value. Shared by the Text pane and the Node pane.
sealed class JsonNode {
  const JsonNode();
}

class JsonObject extends JsonNode {
  const JsonObject(this.members);

  /// In source order. Duplicate keys are kept as they appear.
  final List<JsonMember> members;
}

class JsonMember {
  const JsonMember(this.key, this.value);

  final String key;
  final JsonNode value;
}

class JsonArray extends JsonNode {
  const JsonArray(this.items);

  final List<JsonNode> items;
}

class JsonString extends JsonNode {
  const JsonString(this.value);

  final String value;
}

class JsonNumber extends JsonNode {
  const JsonNumber(this.text);

  /// The literal as written (`1e5`, `1.0`), so saving never changes a number.
  final String text;
}

class JsonBool extends JsonNode {
  const JsonBool(this.value);

  final bool value;
}

class JsonNull extends JsonNode {
  const JsonNull();
}

class JsonDocument {
  const JsonDocument(this.root);

  final JsonNode root;

  /// Pretty-printed with a 2-space indent (used by Save, decision #28).
  String toText() {
    final out = StringBuffer();
    _write(root, out, '');
    return out.toString();
  }
}

void _write(JsonNode node, StringBuffer out, String indent) {
  final inner = '$indent  ';
  switch (node) {
    case JsonObject(:final members) when members.isEmpty:
      out.write('{}');
    case JsonObject(:final members):
      out.writeln('{');
      for (var i = 0; i < members.length; i++) {
        out.write('$inner${jsonEncode(members[i].key)}: ');
        _write(members[i].value, out, inner);
        out.writeln(i < members.length - 1 ? ',' : '');
      }
      out.write('$indent}');
    case JsonArray(:final items) when items.isEmpty:
      out.write('[]');
    case JsonArray(:final items):
      out.writeln('[');
      for (var i = 0; i < items.length; i++) {
        out.write(inner);
        _write(items[i], out, inner);
        out.writeln(i < items.length - 1 ? ',' : '');
      }
      out.write('$indent]');
    case JsonString(:final value):
      out.write(jsonEncode(value));
    case JsonNumber(:final text):
      out.write(text);
    case JsonBool(:final value):
      out.write(value);
    case JsonNull():
      out.write('null');
  }
}

/// Where and why parsing failed. [line] and [column] are 1-based;
/// [column] counts characters.
class JsonParseError {
  const JsonParseError(this.line, this.column, this.message);

  final int line;
  final int column;
  final String message;

  @override
  String toString() => 'Line $line, column $column: $message';
}

sealed class ParseResult {
  const ParseResult();
}

class ParseSuccess extends ParseResult {
  const ParseSuccess(this.document);

  final JsonDocument document;
}

class ParseFailure extends ParseResult {
  const ParseFailure(this.error);

  final JsonParseError error;
}

/// Parses [text] as one JSON value (RFC 8259).
ParseResult parse(String text) {
  final parser = _Parser(text);
  try {
    return ParseSuccess(JsonDocument(parser.parseDocument()));
  } on _Failure catch (f) {
    return ParseFailure(parser.errorAt(f.offset, f.message));
  }
}

class _Failure implements Exception {
  const _Failure(this.offset, this.message);

  final int offset;
  final String message;
}

final _number = RegExp(r'-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?');
final _bareWord = RegExp(r'[A-Za-z0-9_.+-]+');

/// Deeper input is rejected so recursion (here and in toText) cannot
/// overflow the stack.
const maxDepth = 512;

class _Parser {
  _Parser(this.text);

  final String text;
  int pos = 0;
  int depth = 0;

  JsonNode parseDocument() {
    if (text.startsWith('\uFEFF')) pos = 1; // Byte order mark (RFC 8259 §8.1).
    final value = parseValue();
    skipWhitespace();
    if (pos < text.length) {
      throw _Failure(pos, 'Unexpected content after the JSON value');
    }
    return value;
  }

  JsonNode parseValue() {
    skipWhitespace();
    if (pos >= text.length) throw _Failure(pos, 'Unexpected end of input');
    final c = text[pos];
    if (c == '{' || c == '[') {
      if (++depth > maxDepth) {
        throw _Failure(pos, 'Nesting is too deep (over $maxDepth levels)');
      }
      final node = c == '{' ? parseObject() : parseArray();
      depth--;
      return node;
    }
    if (c == '"') return JsonString(parseString());
    if (c == '-' || isDigit(c)) return parseNumber();
    for (final (word, node) in const [
      ('true', JsonBool(true)),
      ('false', JsonBool(false)),
      ('null', JsonNull()),
    ]) {
      if (text.startsWith(word, pos) && !isWordChar(pos + word.length)) {
        pos += word.length;
        return node;
      }
    }
    final word = _bareWord.matchAsPrefix(text, pos)?[0] ?? c;
    throw _Failure(pos, "Unexpected '$word'");
  }

  JsonObject parseObject() {
    pos++; // {
    final members = <JsonMember>[];
    skipWhitespace();
    if (peek('}')) {
      pos++;
      return JsonObject(members);
    }
    while (true) {
      skipWhitespace();
      if (pos >= text.length) throw _Failure(pos, 'Unexpected end of input');
      if (text[pos] != '"') {
        throw _Failure(pos, 'Expected a "quoted" key');
      }
      final key = parseString();
      skipWhitespace();
      consume(':', "Expected ':' after the key");
      final value = parseValue();
      members.add(JsonMember(key, value));
      skipWhitespace();
      if (peek('}')) {
        pos++;
        return JsonObject(members);
      }
      consume(',', "Expected ',' or '}'");
      skipWhitespace();
      if (peek('}')) throw _Failure(pos, 'Trailing comma before }');
    }
  }

  JsonArray parseArray() {
    pos++; // [
    final items = <JsonNode>[];
    skipWhitespace();
    if (peek(']')) {
      pos++;
      return JsonArray(items);
    }
    while (true) {
      items.add(parseValue());
      skipWhitespace();
      if (peek(']')) {
        pos++;
        return JsonArray(items);
      }
      consume(',', "Expected ',' or ']'");
      skipWhitespace();
      if (peek(']')) throw _Failure(pos, 'Trailing comma before ]');
    }
  }

  /// Finds the closing quote, then lets dart:convert decode the escapes.
  String parseString() {
    final start = pos;
    var i = pos + 1;
    while (i < text.length && text[i] != '"') {
      if (text[i] == '\\') i++;
      i++;
    }
    if (i >= text.length) throw _Failure(start, 'Unterminated string');
    pos = i + 1;
    try {
      return jsonDecode(text.substring(start, pos)) as String;
    } on FormatException {
      throw _Failure(start, 'Invalid string (bad escape or control character)');
    }
  }

  JsonNumber parseNumber() {
    final match = _number.matchAsPrefix(text, pos);
    if (match == null || isWordChar(match.end)) {
      throw _Failure(pos, 'Invalid number');
    }
    pos = match.end;
    return JsonNumber(match[0]!);
  }

  void consume(String char, String message) {
    if (pos >= text.length) throw _Failure(pos, 'Unexpected end of input');
    if (text[pos] != char) throw _Failure(pos, message);
    pos++;
  }

  bool peek(String char) => pos < text.length && text[pos] == char;

  bool isDigit(String c) => c.compareTo('0') >= 0 && c.compareTo('9') <= 0;

  bool isWordChar(int i) =>
      i < text.length && _bareWord.matchAsPrefix(text[i]) != null;

  void skipWhitespace() {
    while (pos < text.length && ' \t\n\r'.contains(text[pos])) {
      pos++;
    }
  }

  JsonParseError errorAt(int offset, String message) {
    var line = 1;
    var lineStart = 0;
    for (var i = 0; i < offset && i < text.length; i++) {
      if (text[i] == '\n') {
        line++;
        lineStart = i + 1;
      }
    }
    // Count characters (code points), not UTF-16 units, as the user sees them.
    final column = text.substring(lineStart, offset).runes.length + 1;
    return JsonParseError(line, column, message);
  }
}
