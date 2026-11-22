import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_better_editor/app/app.dart';
import 'package:json_better_editor/document/json_document.dart';
import 'package:json_better_editor/l10n/app_localizations.dart';
import 'package:json_better_editor/ui/file_access.dart';
import 'package:json_better_editor/ui/main_window.dart';
import 'package:material_ui/material_ui.dart';

import 'editor_support.dart';

const windowChannel = MethodChannel('json_better_editor/window');

/// Open → Save → open again gives the same text (#94).
const samples = {
  'duplicate keys': '{"a": 1, "a": 2, "a": {"a": null}}',
  'number text': '[1.0, 1e5, -0.0, 1E-7, 12345678901234567890123]',
  'escapes':
      r'{"t": "tab\there", "q": "say \"hi\"", "u": "é\u0000", "s": "a\/b"}',
  'emoji': '{"😀": "🎉👍🏽", "flag": "🇹🇭"}',
  'Thai': '{"ชื่อ": "สมชาย ใจดี", "ภาษา": ["ไทย", "อังกฤษ"]}',
  'nested and empty': '{"o": {}, "a": [], "deep": [[[{"x": [true, false]}]]]}',
};

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(windowChannel, (_) async => null);
  });

  for (final MapEntry(key: name, value: source) in samples.entries) {
    testWidgets('$name: saving twice gives the same text and values', (
      tester,
    ) async {
      final files = {'/d/a.json': source};
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MainWindow(
            pickJsonFile: () async =>
                PickedFile(path: '/d/a.json', text: files['/d/a.json']!),
            writeTextFile: (path, text) async => files[path] = text,
            fileModifiedTime: (_) async => null,
          ),
        ),
      );

      await pressCmd(tester, LogicalKeyboardKey.keyO);
      await pressCmd(tester, LogicalKeyboardKey.keyS);
      final first = files['/d/a.json']!;
      await pressCmd(tester, LogicalKeyboardKey.keyO); // Open again.
      await pressCmd(tester, LogicalKeyboardKey.keyS);
      final second = files['/d/a.json']!;

      expect(second, first);
      final before = (parse(source) as ParseSuccess).document.toText();
      final after = (parse(second) as ParseSuccess).document.toText();
      expect(after, before, reason: 'same keys, order, numbers and strings');
    }, variant: macOS);
  }
}
