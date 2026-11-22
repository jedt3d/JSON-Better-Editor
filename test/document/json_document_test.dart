import 'package:flutter_test/flutter_test.dart';
import 'package:json_better_editor/document/json_document.dart';

JsonNode rootOf(String text) {
  final result = parse(text);
  expect(result, isA<ParseSuccess>(), reason: 'should parse: $text');
  return (result as ParseSuccess).document.root;
}

JsonParseError errorOf(String text) {
  final result = parse(text);
  expect(result, isA<ParseFailure>(), reason: 'should fail: $text');
  return (result as ParseFailure).error;
}

void main() {
  group('parses each JSON type', () {
    test('string, with escapes', () {
      final node = rootOf(r'"a\"b\né"');
      expect(node, isA<JsonString>());
      expect((node as JsonString).value, 'a"b\né');
    });

    test('number keeps its original text', () {
      for (final text in ['0', '-12', '3.14', '1e5', '-2.5E-3', '1.0']) {
        final node = rootOf(text);
        expect(node, isA<JsonNumber>(), reason: text);
        expect((node as JsonNumber).text, text);
      }
    });

    test('booleans', () {
      expect((rootOf('true') as JsonBool).value, isTrue);
      expect((rootOf('false') as JsonBool).value, isFalse);
    });

    test('null', () {
      expect(rootOf('null'), isA<JsonNull>());
    });

    test('object', () {
      final node = rootOf('{"a": 1}') as JsonObject;
      expect(node.members.single.key, 'a');
      expect((node.members.single.value as JsonNumber).text, '1');
    });

    test('array', () {
      final node = rootOf('[1, "x", null]') as JsonArray;
      expect(node.items.map((n) => n.runtimeType),
          [JsonNumber, JsonString, JsonNull]);
    });
  });

  test('nested structures', () {
    final root = rootOf('{"list": [{"deep": [true]}], "empty": {}, "none": []}')
        as JsonObject;
    final list = root.members[0].value as JsonArray;
    final inner = list.items.single as JsonObject;
    final deep = inner.members.single.value as JsonArray;
    expect((deep.items.single as JsonBool).value, isTrue);
    expect((root.members[1].value as JsonObject).members, isEmpty);
    expect((root.members[2].value as JsonArray).items, isEmpty);
  });

  test('object key order is preserved through parse and serialize', () {
    final root = rootOf('{"zeta": 1, "alpha": 2, "mid": 3}') as JsonObject;
    expect(root.members.map((m) => m.key), ['zeta', 'alpha', 'mid']);

    final text = (parse('{"zeta": 1, "alpha": 2, "mid": 3}') as ParseSuccess)
        .document
        .toText();
    expect(text.indexOf('zeta') < text.indexOf('alpha'), isTrue);
    expect(text.indexOf('alpha') < text.indexOf('mid'), isTrue);
  });

  test('toText pretty-prints with 2-space indent', () {
    final doc = (parse('{"a":[1,{"b":"x\\"y"}],"c":{},"d":[],"e":null}')
            as ParseSuccess)
        .document;
    expect(doc.toText(), '''
{
  "a": [
    1,
    {
      "b": "x\\"y"
    }
  ],
  "c": {},
  "d": [],
  "e": null
}''');
  });

  test('toText round-trips back to the same text', () {
    const pretty = '{\n  "n": 1e5,\n  "s": "é",\n  "t": true\n}';
    expect((parse(pretty) as ParseSuccess).document.toText(), pretty);
  });

  group('reports errors with line and column', () {
    test('trailing comma in an object', () {
      final e = errorOf('{\n  "a": 1,\n}');
      expect((e.line, e.column), (3, 1));
      expect(e.message, contains('Trailing comma'));
    });

    test('trailing comma in an array', () {
      final e = errorOf('[1, 2,]');
      expect((e.line, e.column), (1, 7));
      expect(e.message, contains('Trailing comma'));
    });

    test('unclosed brace', () {
      final e = errorOf('{\n  "a": 1\n');
      expect((e.line, e.column), (3, 1));
      expect(e.message, contains('end of input'));
    });

    test('bad token', () {
      final e = errorOf('{"a": tru}');
      expect((e.line, e.column), (1, 7));
    });

    test('content after the value', () {
      final e = errorOf('{} x');
      expect((e.line, e.column), (1, 4));
    });

    test('empty input', () {
      final e = errorOf('  ');
      expect((e.line, e.column), (1, 3));
    });

    test('invalid number', () {
      final e = errorOf('[01]');
      expect((e.line, e.column), (1, 2));
    });

    test('unterminated string', () {
      final e = errorOf('{"a": "abc');
      expect((e.line, e.column), (1, 7));
    });
  });
}
