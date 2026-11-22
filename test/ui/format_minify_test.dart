import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_better_editor/app/app.dart';
import 'package:json_better_editor/document/json_document.dart';
import 'package:json_better_editor/l10n/app_localizations.dart';
import 'package:json_better_editor/ui/file_access.dart';
import 'package:json_better_editor/ui/main_window.dart';
import 'package:material_ui/material_ui.dart';
import 'package:re_editor/re_editor.dart';

import 'editor_support.dart';

const windowChannel = MethodChannel('json_better_editor/window');

/// Duplicate keys, number text that jsonDecode would change, escapes.
const source = '{"b": 1.0, "a": [1e5, "x\\ty"], "b": {"c": null}}';

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(windowChannel, (_) async => null);
  });

  Future<CodeLineEditingController> openText(
    WidgetTester tester,
    String text,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MainWindow(
          pickJsonFile: () async => PickedFile(path: '/d/a.json', text: text),
        ),
      ),
    );
    await pressCmd(tester, LogicalKeyboardKey.keyO);
    return editorController(tester);
  }

  Future<void> menu(WidgetTester tester, String item) async {
    // Not awaited: an error keeps the request open until its dialog closes.
    tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      windowChannel.name,
      windowChannel.codec.encodeMethodCall(MethodCall('menu', item)),
      (_) {},
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Format pretty-prints, keeping order, duplicates and numbers', (
    tester,
  ) async {
    final c = await openText(tester, source);
    await menu(tester, 'format');
    expect(
      c.text,
      '{\n'
      '  "b": 1.0,\n'
      '  "a": [\n'
      '    1e5,\n'
      '    "x\\ty"\n'
      '  ],\n'
      '  "b": {\n'
      '    "c": null\n'
      '  }\n'
      '}',
    );
  }, variant: macOS);

  testWidgets('Minify puts it on one line, keeping the same things', (
    tester,
  ) async {
    final c = await openText(tester, '{\n  "b": 1.0,\n  "b": [1e5]\n}');
    await menu(tester, 'minify');
    expect(c.text, '{"b":1.0,"b":[1e5]}');
  }, variant: macOS);

  testWidgets('one Cmd+Z undoes Format, and one undoes Minify', (tester) async {
    final c = await openText(tester, source);
    await menu(tester, 'format');
    await pressCmd(tester, LogicalKeyboardKey.keyZ);
    expect(c.text, source);
    await menu(tester, 'minify');
    expect(c.text, '{"b":1.0,"a":[1e5,"x\\ty"],"b":{"c":null}}');
    await pressCmd(tester, LogicalKeyboardKey.keyZ);
    expect(c.text, source);
  }, variant: macOS);

  testWidgets('invalid JSON shows the error and changes nothing', (
    tester,
  ) async {
    final c = await openText(tester, '[1]');
    c.text = '[1,\n 2,]';
    await tester.pumpAndSettle();
    for (final item in ['format', 'minify']) {
      await menu(tester, item);
      expect(find.textContaining('Line 2, column 4'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(c.text, '[1,\n 2,]');
    }
  }, variant: macOS);

  test('compact text of every value type', () {
    final document =
        (parse('[true, false, null, "é", -0.5, {}, []]') as ParseSuccess)
            .document;
    expect(document.toCompactText(), '[true,false,null,"é",-0.5,{},[]]');
  });
}
