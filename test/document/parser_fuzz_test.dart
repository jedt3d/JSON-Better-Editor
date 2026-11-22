import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:json_better_editor/document/json_document.dart';

/// Randomized check (#94): our parser accepts and rejects exactly the same
/// texts as dart:convert's jsonDecode. Fixed seed, so failures repeat.
///
/// Allowed differences (never generated here, covered by their own tests in
/// json_document_test.dart):
/// - nesting deeper than 512 levels: we reject it (decision #40), jsonDecode
///   accepts it;
/// - a leading byte order mark: we skip it (RFC 8259 §8.1), jsonDecode
///   rejects it.
/// Duplicate keys are accepted by both (we keep every copy, jsonDecode keeps
/// the last), so they are generated.
void main() {
  final random = Random(20261123);

  String pick(List<String> options) => options[random.nextInt(options.length)];

  String string() {
    const pieces = [
      'a',
      'key',
      'Ä',
      'é',
      'ไทย',
      '😀',
      ' ',
      r'\n',
      r'\t',
      r'\"',
      r'\\',
      r'\/',
      r'é',
      r'😀',
      r'\b',
      r'\f',
      r'\r',
      '',
    ];
    return '"${List.generate(random.nextInt(4), (_) => pick(pieces)).join()}"';
  }

  String number() => pick([
    '0',
    '-0',
    '1',
    '-12',
    '3.25',
    '1.0',
    '1e5',
    '1E-3',
    '-0.5e+10',
    '123456789012345678901234567890',
  ]);

  String ws() => pick(['', '', ' ', '\n', '  ', '\t', '\r\n']);

  late String Function(int depth) value;

  String array(int depth) {
    final n = random.nextInt(4);
    return '[${ws()}${List.generate(n, (_) => value(depth + 1)).join(',${ws()}')}${ws()}]';
  }

  value = (int depth) {
    final kind = depth > 4 ? random.nextInt(5) : random.nextInt(7);
    switch (kind) {
      case 0:
        return string();
      case 1:
        return number();
      case 2:
        return pick(['true', 'false', 'null']);
      case 3:
      case 4:
        return depth > 4 ? number() : array(depth);
      default:
        final n = random.nextInt(4);
        final keys = List.generate(
          n,
          (_) => random.nextBool() ? '"k"' : string(),
        );
        return '{${ws()}${[for (final k in keys) '$k${ws()}:${ws()}${value(depth + 1)}'].join(',${ws()}')}${ws()}}';
    }
  };

  /// Small edits that usually (not always) make JSON invalid.
  String mutate(String text) {
    if (text.isEmpty) return '{';
    final i = random.nextInt(text.length);
    return switch (random.nextInt(8)) {
      0 => text.substring(0, i) + text.substring(i + 1), // Delete a char.
      1 =>
        text.substring(0, i) +
            pick([
              ',',
              ':',
              '}',
              ']',
              '"',
              '{',
              '[',
              'x',
              '\\',
              '.',
              '-',
              '+',
              '0',
              '\u0001',
            ]) +
            text.substring(i),
      2 => '$text,',
      3 => '$text ${value(0)}',
      4 => text.replaceFirst(']', ',]'),
      5 => text.replaceFirst('}', ',}'),
      6 => text.replaceFirst('true', 'True'),
      _ => text.substring(0, i),
    };
  }

  bool accepts(String text) => parse(text) is ParseSuccess;

  bool jsonDecodeAccepts(String text) {
    try {
      jsonDecode(text);
      return true;
    } on FormatException {
      return false;
    }
  }

  test('agrees with jsonDecode on 2,000 valid and invalid texts', () {
    var valid = 0;
    var invalid = 0;
    final disagreements = <String>[];
    for (var i = 0; i < 1000; i++) {
      final good = '${ws()}${value(0)}${ws()}';
      final bad = mutate(good);
      for (final text in [good, bad]) {
        final ours = accepts(text);
        if (ours != jsonDecodeAccepts(text)) disagreements.add(text);
        ours ? valid++ : invalid++;
      }
    }
    expect(
      disagreements,
      isEmpty,
      reason: disagreements.take(5).join('\n---\n'),
    );
    expect(valid, greaterThan(1000), reason: 'valid texts generated');
    expect(invalid, greaterThan(300), reason: 'invalid texts generated');
  });

  test('accepted texts give the same values as jsonDecode', () {
    for (var i = 0; i < 500; i++) {
      final text = value(0);
      final document = (parse(text) as ParseSuccess).document;
      // Our pretty text (numbers kept as written) decodes to the same value,
      // except that duplicate keys keep only the last copy in jsonDecode.
      expect(jsonDecode(document.toText()), jsonDecode(text), reason: text);
    }
  });
}
