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

/// #54: with a dialog open, menu shortcuts reached the editor behind it and
/// Return did not press OK.
void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(windowChannel, (_) async => null);
  });

  Future<CodeLineEditingController> openWithSaveError(
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MainWindow(
          pickJsonFile: () async =>
              const PickedFile(path: '/d/a.json', text: '{"a": 1}'),
          writeTextFile: (_, _) async {},
        ),
      ),
    );
    await pressCmd(tester, LogicalKeyboardKey.keyO);
    await tester.tap(textEditor);
    await tester.pumpAndSettle();
    final c = editorController(tester)
      ..selection = const CodeLineSelection.collapsed(index: 0, offset: 1);
    await tester.pump();
    await typeText(tester, 'xyz');
    await pressCmd(tester, LogicalKeyboardKey.keyS); // Invalid: error dialog.
    expect(find.byType(AlertDialog), findsOneWidget);
    return c;
  }

  Future<void> menu(WidgetTester tester, String method, String arg) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      windowChannel.name,
      windowChannel.codec.encodeMethodCall(MethodCall(method, arg)),
      (_) {},
    );
    await tester.pumpAndSettle();
  }

  testWidgets('menu actions do nothing while a dialog is open', (tester) async {
    final c = await openWithSaveError(tester);
    await menu(tester, 'edit', 'undo');
    await menu(tester, 'edit', 'selectAll');
    await menu(tester, 'menu', 'new');
    expect(c.text, '{xyz"a": 1}');
    expect(c.selection.isCollapsed, isTrue);
    expect(find.byType(AlertDialog), findsOneWidget);
  }, variant: macOS);

  testWidgets('Return presses OK', (tester) async {
    await openWithSaveError(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  }, variant: macOS);

  testWidgets('after the dialog closes, editor shortcuts work again', (
    tester,
  ) async {
    final c = await openWithSaveError(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await pressCmd(tester, LogicalKeyboardKey.keyA);
    expect(c.selectedText, '{xyz"a": 1}');
    await pressCmd(tester, LogicalKeyboardKey.keyZ);
    expect(c.text, '{"a": 1}');
  }, variant: macOS);

  testWidgets('a file from Finder waits until the dialog is closed', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MainWindow(
          pickJsonFile: () async =>
              const PickedFile(path: '/d/a.json', text: '{"a": 1}'),
          readJsonFile: (path) async => PickedFile(path: path, text: '[2]'),
          writeTextFile: (_, _) async {},
        ),
      ),
    );
    await pressCmd(tester, LogicalKeyboardKey.keyO);
    await tester.tap(textEditor);
    await tester.pumpAndSettle();
    editorController(tester).selection = const CodeLineSelection.collapsed(
      index: 0,
      offset: 1,
    );
    await tester.pump();
    await typeText(tester, 'xyz');
    await pressCmd(tester, LogicalKeyboardKey.keyS); // Error dialog.

    await menu(tester, 'openPath', '/d/b.json');
    expect(editorController(tester).text, '{xyz"a": 1}', reason: 'waits');

    await tester.sendKeyEvent(LogicalKeyboardKey.enter); // OK
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(
      find.text('Do you want to save the changes made to “a.json”?'),
      findsOneWidget,
      reason: 'then opens, asking about the edits first',
    );
    await tester.tap(find.text("Don't Save"));
    await tester.pumpAndSettle();
    expect(editorController(tester).text, '[2]');
  }, variant: macOS);
}
