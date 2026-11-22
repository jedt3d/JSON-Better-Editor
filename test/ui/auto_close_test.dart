import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_better_editor/app/app.dart';
import 'package:json_better_editor/l10n/app_localizations.dart';
import 'package:json_better_editor/ui/main_window.dart';
import 'package:material_ui/material_ui.dart';
import 'package:re_editor/re_editor.dart';

import 'editor_support.dart';

const windowChannel = MethodChannel('json_better_editor/window');

/// Auto-close and type-over (#91, fork patch 2).
void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(windowChannel, (_) async => null);
  });

  /// A new document holding `{}`, caret between the braces.
  Future<CodeLineEditingController> newDocument(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MainWindow(pickJsonFile: () async => null),
      ),
    );
    await pressCmd(tester, LogicalKeyboardKey.keyN);
    await tester.tap(textEditor);
    await tester.pumpAndSettle();
    final c = editorController(tester)
      ..selection = const CodeLineSelection.collapsed(index: 0, offset: 1);
    await tester.pumpAndSettle();
    return c;
  }

  for (final (open, close) in [('{', '}'), ('[', ']'), ('"', '"')]) {
    testWidgets('$open inserts $open$close with the caret between', (
      tester,
    ) async {
      final c = await newDocument(tester);
      await typeChars(tester, open);
      expect(c.text, '{$open$close}');
      expect(c.selection.extentOffset, 2);
    }, variant: macOS);

    testWidgets('typing $close before the auto-inserted $close moves past it', (
      tester,
    ) async {
      final c = await newDocument(tester);
      await typeChars(tester, '${open}x$close');
      expect(c.text, '{${open}x$close}');
      expect(c.selection.extentOffset, 4);
    }, variant: macOS);
  }

  testWidgets('"x": 1 types exactly', (tester) async {
    final c = await newDocument(tester);
    await typeChars(tester, '"x": 1');
    expect(c.text, '{"x": 1}');
  }, variant: macOS);

  testWidgets('"a": ["b", {"c": true}] types exactly', (tester) async {
    final c = await newDocument(tester);
    await typeChars(tester, '"a": ["b", {"c": true}]');
    expect(c.text, '{"a": ["b", {"c": true}]}');
  }, variant: macOS);

  for (final pair in ['[]', '""', '{}']) {
    testWidgets('Backspace right after an empty $pair deletes both', (
      tester,
    ) async {
      final c = await newDocument(tester);
      await typeChars(tester, pair[0]);
      expect(c.text, '{$pair}');
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pumpAndSettle();
      expect(c.text, '{}');
    }, variant: macOS);
  }
}
