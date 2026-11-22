import 'package:flutter_test/flutter_test.dart';
import 'package:json_better_editor/document/recent_files.dart';

void main() {
  test('newest first; reopening moves a file to the front', () {
    var list = <String>[];
    for (final p in ['/a', '/b', '/c']) {
      list = addRecentFile(list, p);
    }
    expect(list, ['/c', '/b', '/a']);
    expect(addRecentFile(list, '/a'), ['/a', '/c', '/b']);
  });

  test('keeps at most 10, dropping the oldest', () {
    var list = <String>[];
    for (var i = 0; i < 12; i++) {
      list = addRecentFile(list, '/f$i');
    }
    expect(list, hasLength(maxRecentFiles));
    expect(list.first, '/f11');
    expect(list.last, '/f2');
  });
}
