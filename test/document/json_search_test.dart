import 'package:flutter_test/flutter_test.dart';
import 'package:json_better_editor/document/json_search.dart';

List<SearchMatch> find(String text, String query) {
  return searchJson(text.split('\n'), query);
}

void main() {
  test('finds keys and string values, case-insensitive', () {
    expect(find('{"name": "Nancy"}', 'n'), [
      (line: 0, start: 2, end: 3),
      (line: 0, start: 10, end: 11),
      (line: 0, start: 12, end: 13),
    ]);
  });

  test('finds numbers, booleans and null', () {
    expect(find('[12, true, null]', '1'), [(line: 0, start: 1, end: 2)]);
    expect(find('[12, true, null]', 'ru'), [(line: 0, start: 6, end: 8)]);
    expect(find('[12, true, null]', 'null'), [(line: 0, start: 11, end: 15)]);
  });

  test('never matches punctuation or the space between tokens', () {
    expect(find('{"a": [1, 2]}', ':'), isEmpty);
    expect(find('{"a": [1, 2]}', ','), isEmpty);
    expect(find('{"a": [1, 2]}', '"'), isEmpty);
    expect(find('{"a": [1, 2]}', ' '), isEmpty);
    expect(find('{"a, b": 1}', ','), [(line: 0, start: 3, end: 4)]);
  });

  test('matches on several lines, in order', () {
    expect(find('{\n  "ab": "x",\n  "b": "abc"\n}', 'ab'), [
      (line: 1, start: 3, end: 5),
      (line: 2, start: 8, end: 10),
    ]);
  });

  test('no match and empty query', () {
    expect(find('{"a": 1}', 'zzz'), isEmpty);
    expect(find('{"a": 1}', ''), isEmpty);
  });

  test('next and previous wrap around', () {
    final m = find('["a", "a", "a"]', 'a'); // columns 2, 7, 12
    expect(nextMatch(m, (line: 0, column: 0)), 0);
    expect(nextMatch(m, (line: 0, column: 2)), 1);
    expect(nextMatch(m, (line: 0, column: 12)), 0, reason: 'wraps');
    expect(nextMatch(m, (line: 0, column: 7), forward: false), 0);
    expect(nextMatch(m, (line: 0, column: 2), forward: false), 2);
    expect(nextMatch(const [], (line: 0, column: 0)), -1);
  });
}
