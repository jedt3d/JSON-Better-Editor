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
    '  "role": "analyst",\n'
    '  "tags": ["data", "math"],\n'
    '  "age": 36\n'
    '}';

Future<CodeLineEditingController> openDoc(WidgetTester tester) async {
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
  return editorController(tester);
}

final field = find.byKey(const Key('searchField'));

String status(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('searchStatus'))).data!;

void main() {
  testWidgets('Cmd+F opens the search field with the keyboard in it', (
    tester,
  ) async {
    await openDoc(tester);
    expect(field, findsNothing);
    await pressCmd(tester, LogicalKeyboardKey.keyF);
    expect(field, findsOneWidget);
    final editable = tester.widget<EditableText>(
      find.descendant(of: field, matching: find.byType(EditableText)),
    );
    expect(editable.focusNode.hasFocus, isTrue);
  }, variant: macOS);

  testWidgets('the toolbar Search button opens it too', (tester) async {
    await openDoc(tester);
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    expect(field, findsOneWidget);
  }, variant: macOS);

  testWidgets('typing selects the first match in a key, with a count', (
    tester,
  ) async {
    final controller = await openDoc(tester);
    await pressCmd(tester, LogicalKeyboardKey.keyF);
    await tester.enterText(field, 'a');
    await tester.pumpAndSettle();
    expect(controller.selection.extentIndex, 1);
    expect(controller.selectedText, 'a', reason: '"n[a]me" on line 2');
    expect(controller.selection.startOffset, 4);
    expect(status(tester), '1 of 10');
  }, variant: macOS);

  testWidgets('a value match is selected and counted', (tester) async {
    final controller = await openDoc(tester);
    await pressCmd(tester, LogicalKeyboardKey.keyF);
    await tester.enterText(field, 'MATH');
    await tester.pumpAndSettle();
    expect(controller.selection.extentIndex, 3);
    expect(controller.selectedText, 'math');
    expect(status(tester), '1 of 1');
  }, variant: macOS);

  testWidgets('punctuation is not searched', (tester) async {
    await openDoc(tester);
    await pressCmd(tester, LogicalKeyboardKey.keyF);
    await tester.enterText(field, ':');
    await tester.pumpAndSettle();
    expect(status(tester), 'No results');
  }, variant: macOS);

  testWidgets('no match shows "No results" and leaves the selection', (
    tester,
  ) async {
    final controller = await openDoc(tester);
    controller.selection = const CodeLineSelection.collapsed(
      index: 2,
      offset: 3,
    );
    await tester.pumpAndSettle();
    await pressCmd(tester, LogicalKeyboardKey.keyF);
    await tester.enterText(field, 'zebra');
    await tester.pumpAndSettle();
    expect(status(tester), 'No results');
    expect(
      controller.selection,
      const CodeLineSelection.collapsed(index: 2, offset: 3),
    );
  }, variant: macOS);
}
