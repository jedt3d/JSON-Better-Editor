import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_better_editor/app/app.dart';
import 'package:json_better_editor/l10n/app_localizations.dart';
import 'package:json_better_editor/ui/file_access.dart';
import 'package:json_better_editor/ui/main_window.dart';
import 'package:material_ui/material_ui.dart';
import 'package:re_editor/re_editor.dart';

import 'editor_support.dart';

const windowChannel = MethodChannel('json_better_editor/window');

/// The JSON status item in the Status Bar (#99).
void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(windowChannel, (_) async => null);
  });

  final status = find.byKey(const Key('jsonStatus'));

  String statusText(WidgetTester tester) => tester
      .widget<Text>(find.descendant(of: status, matching: find.byType(Text)))
      .data!;

  Future<CodeLineEditingController> openText(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MainWindow(
          pickJsonFile: () async =>
              const PickedFile(path: '/d/a.json', text: '[1]'),
          writeTextFile: (_, _) async {},
          fileModifiedTime: (_) async => null,
        ),
      ),
    );
    await pressCmd(tester, LogicalKeyboardKey.keyO);
    return editorController(tester);
  }

  Future<void> edit(
    WidgetTester tester,
    CodeLineEditingController c,
    String text,
  ) async {
    c.text = text;
    await tester.pumpAndSettle();
  }

  testWidgets('after Open: ✓ Valid JSON', (tester) async {
    await openText(tester);
    expect(statusText(tester), '✓ Valid JSON');
  }, variant: macOS);

  testWidgets('after an edit: Not checked since edit; undo brings ✓ back', (
    tester,
  ) async {
    final c = await openText(tester);
    c
      ..selection = const CodeLineSelection.collapsed(index: 0, offset: 2)
      ..replaceSelection(', 2');
    await tester.pumpAndSettle();
    expect(statusText(tester), 'Not checked since edit');
    await pressCmd(tester, LogicalKeyboardKey.keyZ);
    expect(statusText(tester), '✓ Valid JSON');
  }, variant: macOS);

  testWidgets('clicking Not checked runs Validate JSON: ✗ Invalid JSON', (
    tester,
  ) async {
    final c = await openText(tester);
    await edit(tester, c, '[1,]');
    await tester.tap(status);
    await tester.pumpAndSettle();
    expect(find.text('Invalid JSON'), findsOneWidget, reason: 'the dialog');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(statusText(tester), '✗ Invalid JSON · 1 error');
  }, variant: macOS);

  testWidgets('Save records the result too (valid and invalid)', (
    tester,
  ) async {
    final c = await openText(tester);
    await edit(tester, c, '[1, 2]');
    await pressCmd(tester, LogicalKeyboardKey.keyS);
    expect(statusText(tester), '✓ Valid JSON');

    await edit(tester, c, '[1, 2');
    await pressCmd(tester, LogicalKeyboardKey.keyS);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(statusText(tester), '✗ Invalid JSON · 1 error');
  }, variant: macOS);

  testWidgets('folding is not an edit', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MainWindow(
          pickJsonFile: () async =>
              const PickedFile(path: '/d/a.json', text: '[\n  1,\n  2\n]'),
        ),
      ),
    );
    await pressCmd(tester, LogicalKeyboardKey.keyO);
    editorController(tester).collapseChunk(0, 4);
    await tester.pumpAndSettle();
    expect(statusText(tester), '✓ Valid JSON');
  }, variant: macOS);
}
