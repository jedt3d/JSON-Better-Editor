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
const original = '{"a": [1, 2]}';

void main() {
  String? clipboard;

  setUp(() {
    clipboard = null;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      switch (call.method) {
        case 'Clipboard.setData':
          clipboard = (call.arguments as Map)['text'] as String?;
        case 'Clipboard.getData':
          return {'text': clipboard};
        case 'Clipboard.hasStrings':
          return {'value': clipboard != null};
      }
      return null;
    });
    messenger.setMockMethodCallHandler(windowChannel, (_) async => null);
  });

  Future<CodeLineEditingController> openDoc(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MainWindow(
          pickJsonFile: () async =>
              const PickedFile(path: '/d/a.json', text: original),
          writeTextFile: (_, _) async {},
        ),
      ),
    );
    await pressCmd(tester, LogicalKeyboardKey.keyO);
    await tester.tap(textEditor);
    await tester.pumpAndSettle();
    return editorController(tester);
  }

  Future<void> select(
    WidgetTester tester,
    CodeLineEditingController c,
    int start, [
    int? end,
  ]) async {
    c.selection = CodeLineSelection(
      baseIndex: 0,
      baseOffset: start,
      extentIndex: 0,
      extentOffset: end ?? start,
    );
    await tester.pump();
  }

  Future<void> undo(WidgetTester tester) =>
      pressCmd(tester, LogicalKeyboardKey.keyZ);
  Future<void> redo(WidgetTester tester) =>
      pressCmd(tester, LogicalKeyboardKey.keyZ, shift: true);

  testWidgets('typing is undone and redone', (tester) async {
    final c = await openDoc(tester);
    await select(tester, c, 11);
    await typeText(tester, ', 3');
    expect(c.text, '{"a": [1, 2, 3]}');
    await undo(tester);
    expect(c.text, original);
    await redo(tester);
    expect(c.text, '{"a": [1, 2, 3]}');
  }, variant: macOS);

  testWidgets('paste and cut are undone and redone', (tester) async {
    final c = await openDoc(tester);
    await select(tester, c, 6, 12); // [1, 2]
    await pressCmd(tester, LogicalKeyboardKey.keyX);
    expect(c.text, '{"a": }');
    clipboard = 'null';
    await pressCmd(tester, LogicalKeyboardKey.keyV);
    expect(c.text, '{"a": null}');
    await undo(tester);
    expect(c.text, '{"a": }', reason: 'paste undone');
    await undo(tester);
    expect(c.text, original, reason: 'cut undone');
    await redo(tester);
    await redo(tester);
    expect(c.text, '{"a": null}');
  }, variant: macOS);

  testWidgets('indent is undone', (tester) async {
    final c = await openDoc(tester);
    await select(tester, c, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(c.text, '  $original');
    await undo(tester);
    expect(c.text, original);
  }, variant: macOS);

  testWidgets('the Edit menu undoes and redoes too', (tester) async {
    final c = await openDoc(tester);
    await select(tester, c, 11);
    await typeText(tester, ', 3');
    Future<void> edit(String action) async {
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        windowChannel.name,
        windowChannel.codec.encodeMethodCall(MethodCall('edit', action)),
        (_) {},
      );
      await tester.pumpAndSettle();
    }

    await edit('undo');
    expect(c.text, original);
    await edit('redo');
    expect(c.text, '{"a": [1, 2, 3]}');
  }, variant: macOS);

  testWidgets('New and Open start an empty history; Save keeps it', (
    tester,
  ) async {
    // re_editor also records caret moves, so "empty" is checked as: undo
    // never brings back text from before the New or Open.
    final c = await openDoc(tester);
    await undo(tester);
    expect(c.text, original, reason: 'nothing to undo after Open');

    await select(tester, c, 11);
    await typeText(tester, ', 3');
    await pressCmd(tester, LogicalKeyboardKey.keyS);
    expect(c.canUndo, isTrue, reason: 'Save keeps the history');
    await undo(tester);
    expect(c.text, original);

    await pressCmd(tester, LogicalKeyboardKey.keyN);
    await tester.tap(find.text("Don't Save"));
    await tester.pumpAndSettle();
    final fresh = editorController(tester);
    expect(fresh.canUndo, isFalse, reason: 'fresh after New');
    await undo(tester);
    await undo(tester);
    expect(fresh.text, '{}');

    await pressCmd(tester, LogicalKeyboardKey.keyO);
    final reopened = editorController(tester);
    expect(reopened.canUndo, isFalse, reason: 'fresh after Open');
    await undo(tester);
    expect(reopened.text, original);
  }, variant: macOS);

  testWidgets('caret moves and folds are not undo steps', (tester) async {
    final c = await openDoc(tester);
    await select(tester, c, 11);
    await typeText(tester, ', 3');
    await select(tester, c, 2);
    await select(tester, c, 5);
    await undo(tester);
    expect(c.text, original, reason: 'one Cmd+Z undoes the typing');
    await undo(tester);
    expect(c.text, original, reason: 'nothing earlier: no change');
    await redo(tester);
    expect(c.text, '{"a": [1, 2, 3]}');
  }, variant: macOS);
}
