import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_better_editor/app/app.dart';
import 'package:json_better_editor/l10n/app_localizations.dart';
import 'package:json_better_editor/ui/file_access.dart';
import 'package:json_better_editor/ui/main_window.dart';
import 'package:material_ui/material_ui.dart';
import 'package:re_editor/re_editor.dart';

import 'editor_support.dart';

const doc =
    '{\n'
    '  "name": "Ada",\n'
    '  "nation": "UK",\n'
    '  "langs": ["en", "fr"],\n'
    '  "nested": {"age": 36},\n'
    '  \n'
    '  "last": 1\n'
    '}';

final suggestions = find.byKey(const Key('keySuggestions'));

List<String> shown(WidgetTester tester) => [
  for (final t in tester.widgetList<Text>(
    find.descendant(of: suggestions, matching: find.byType(Text)),
  ))
    t.data!,
];

/// Opens [doc] and types [typed] at line [line], column [column].
Future<CodeLineEditingController> typeAt(
  WidgetTester tester,
  int line,
  int column,
  String typed,
) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MainWindow(
        pickJsonFile: () async =>
            const PickedFile(path: '/d/a.json', text: doc),
      ),
    ),
  );
  await pressCmd(tester, LogicalKeyboardKey.keyO);
  await tester.tap(textEditor);
  await tester.pumpAndSettle();
  final controller = editorController(tester)
    ..selection = CodeLineSelection.collapsed(index: line, offset: column);
  await tester.pump();
  await typeText(tester, typed);
  return controller;
}

void main() {
  testWidgets('typing a key prefix lists matching keys of the document', (
    tester,
  ) async {
    await typeAt(tester, 5, 2, '"na');
    expect(shown(tester), ['name', 'nation']);
  }, variant: macOS);

  testWidgets('keys from nested objects are offered too', (tester) async {
    await typeAt(tester, 5, 2, '"a');
    expect(shown(tester), ['age']);
  }, variant: macOS);

  testWidgets('no list for a value position or inside an array', (
    tester,
  ) async {
    await typeAt(tester, 3, 22, ', "n');
    expect(suggestions, findsNothing, reason: 'in the langs array');
  }, variant: macOS);

  testWidgets('Enter accepts the selected key and closes the quote', (
    tester,
  ) async {
    final controller = await typeAt(tester, 5, 2, '"na');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(controller.codeLines[5].text, '  "nation"');
    expect(suggestions, findsNothing);
  }, variant: macOS);

  testWidgets('Tab does not accept: it indents and the key stays as typed', (
    tester,
  ) async {
    final controller = await typeAt(tester, 5, 2, '"na');
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(controller.codeLines[5].text, '  "na ', reason: 'to column 6');
  }, variant: macOS);

  testWidgets('Esc closes the list and keeps the text', (tester) async {
    final controller = await typeAt(tester, 5, 2, '"na');
    expect(suggestions, findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(suggestions, findsNothing);
    expect(controller.codeLines[5].text, '  "na');
    expect(controller.selection.extentOffset, 5);
  }, variant: macOS);
}
