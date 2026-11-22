import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_better_editor/app/app.dart';
import 'package:json_better_editor/document/json_document.dart';
import 'package:json_better_editor/l10n/app_localizations.dart';
import 'package:json_better_editor/ui/error_popover.dart';
import 'package:json_better_editor/ui/file_access.dart';
import 'package:json_better_editor/ui/main_window.dart';
import 'package:material_ui/material_ui.dart';
import 'package:re_editor/re_editor.dart';

import 'editor_support.dart';

const windowChannel = MethodChannel('json_better_editor/window');

/// The error list popover (#101).
void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(windowChannel, (_) async => null);
  });

  final popover = find.byKey(const Key('errorPopover'));
  final status = find.byKey(const Key('jsonStatus'));

  /// Opens a file, breaks it at line 3, validates, closes the dialog.
  Future<CodeLineEditingController> openInvalid(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MainWindow(
          pickJsonFile: () async =>
              const PickedFile(path: '/d/a.json', text: '[1]'),
        ),
      ),
    );
    await pressCmd(tester, LogicalKeyboardKey.keyO);
    final c = editorController(tester)..text = '{\n  "a": 1,\n  "b" 2\n}';
    await tester.pumpAndSettle();
    await tester.tap(status); // Not checked since edit → Validate.
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    c.selection = const CodeLineSelection.collapsed(index: 0, offset: 0);
    await tester.pumpAndSettle();
    return c;
  }

  testWidgets('clicking ✗ Invalid JSON opens the list with the error row', (
    tester,
  ) async {
    await openInvalid(tester);
    await tester.tap(status);
    await tester.pumpAndSettle();
    expect(popover, findsOneWidget);
    expect(find.text('Location'), findsOneWidget);
    expect(find.text('Error message'), findsOneWidget);
    expect(find.text('Line 3, Col 7'), findsOneWidget);
    expect(find.text("Expected ':' after the key"), findsOneWidget);
  }, variant: macOS);

  testWidgets('double-clicking a row closes it and jumps to the error', (
    tester,
  ) async {
    final c = await openInvalid(tester);
    await tester.tap(status);
    await tester.pumpAndSettle();
    final row = find.byKey(const Key('errorRow0'));
    await tester.tap(row);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(popover, findsNothing);
    expect(c.selection, const CodeLineSelection.collapsed(index: 2, offset: 6));
  }, variant: macOS);

  testWidgets('Return on the selected row jumps too', (tester) async {
    final c = await openInvalid(tester);
    await tester.tap(status);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(popover, findsNothing);
    expect(c.selection.extentIndex, 2);
  }, variant: macOS);

  testWidgets('Esc or a click outside closes it without moving the caret', (
    tester,
  ) async {
    final c = await openInvalid(tester);
    await tester.tap(status);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(popover, findsNothing);

    await tester.tap(status);
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(popover, findsNothing);
    expect(c.selection.extentIndex, 0);
  }, variant: macOS);

  testWidgets('the table already handles many rows', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: Builder(
              builder: (context) => TextButton(
                onPressed: () => showErrorPopover(context, [
                  for (var i = 1; i <= 40; i++)
                    JsonParseError(i, 1, 'Error $i'),
                ]),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Line 1, Col 1'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Error 40'), 100);
    expect(find.text('Error 40'), findsOneWidget);
  }, variant: macOS);
}
