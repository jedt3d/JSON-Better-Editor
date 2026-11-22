import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_better_editor/app/app.dart';
import 'package:json_better_editor/l10n/app_localizations.dart';
import 'package:json_better_editor/ui/file_access.dart';
import 'package:json_better_editor/ui/main_window.dart';
import 'package:material_ui/material_ui.dart';
import 'package:re_editor/re_editor.dart';

import 'editor_support.dart';

Future<CodeLineEditingController> openText(
  WidgetTester tester,
  String text,
  CodeLineSelection selection,
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
  final controller = editorController(tester)..selection = selection;
  await tester.pumpAndSettle();
  return controller;
}

Future<void> tab(WidgetTester tester, {bool shift = false}) async {
  if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.pumpAndSettle();
}

const text = '[\n1,\n  2,\n    3\n]';

void main() {
  testWidgets('Tab inserts 2 spaces at the caret', (tester) async {
    final controller = await openText(
      tester,
      text,
      const CodeLineSelection.collapsed(index: 1, offset: 0),
    );
    await tab(tester);
    expect(controller.text, '[\n  1,\n  2,\n    3\n]');
    expect(controller.selection.extentOffset, 2);
  }, variant: macOS);

  testWidgets('Tab with several lines selected indents every line', (
    tester,
  ) async {
    final controller = await openText(
      tester,
      text,
      const CodeLineSelection(
        baseIndex: 1,
        baseOffset: 0,
        extentIndex: 3,
        extentOffset: 2,
      ),
    );
    await tab(tester);
    expect(controller.text, '[\n  1,\n    2,\n      3\n]');
  }, variant: macOS);

  testWidgets('Shift+Tab removes up to 2 leading spaces from the line', (
    tester,
  ) async {
    final controller = await openText(
      tester,
      text,
      const CodeLineSelection.collapsed(index: 3, offset: 5),
    );
    await tab(tester, shift: true);
    expect(controller.text, '[\n1,\n  2,\n  3\n]');
  }, variant: macOS);

  testWidgets('Shift+Tab on selected lines; nothing to remove is a no-op', (
    tester,
  ) async {
    final controller = await openText(
      tester,
      text,
      const CodeLineSelection(
        baseIndex: 1,
        baseOffset: 0,
        extentIndex: 3,
        extentOffset: 1,
      ),
    );
    await tab(tester, shift: true);
    expect(controller.text, '[\n1,\n2,\n  3\n]', reason: '"1," had none');

    controller.selection = const CodeLineSelection.collapsed(
      index: 1,
      offset: 1,
    );
    await tester.pumpAndSettle();
    await tab(tester, shift: true);
    expect(controller.text, '[\n1,\n2,\n  3\n]');
  }, variant: macOS);
}
