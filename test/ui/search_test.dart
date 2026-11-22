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

  group('Next and Previous (#42)', () {
    // "a" matches: n[a]me, [A]d[a], [a]n[a]lyst, d[a]t[a], m[a]th, [a]ge.
    Future<CodeLineEditingController> searchA(WidgetTester tester) async {
      final controller = await openDoc(tester);
      await pressCmd(tester, LogicalKeyboardKey.keyF);
      await tester.enterText(field, 'a');
      await tester.pumpAndSettle();
      return controller;
    }

    (int, int) at(CodeLineEditingController c) =>
        (c.selection.startIndex, c.selection.startOffset);

    Future<void> key(
      WidgetTester tester,
      LogicalKeyboardKey k, {
      bool shift = false,
    }) async {
      if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(k);
      if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
    }

    testWidgets('Enter goes to the next match, Shift+Enter back', (
      tester,
    ) async {
      final controller = await searchA(tester);
      expect(at(controller), (1, 4));
      await key(tester, LogicalKeyboardKey.enter);
      expect(at(controller), (1, 11));
      expect(status(tester), '2 of 10');
      await key(tester, LogicalKeyboardKey.enter, shift: true);
      expect(at(controller), (1, 4));
      expect(status(tester), '1 of 10');
    }, variant: macOS);

    testWidgets('Cmd+G and Cmd+Shift+G do the same and wrap at the ends', (
      tester,
    ) async {
      final controller = await searchA(tester);
      await pressCmd(tester, LogicalKeyboardKey.keyG, shift: true);
      expect(at(controller), (4, 3), reason: 'wrapped to the last: [a]ge');
      expect(status(tester), '10 of 10');
      await pressCmd(tester, LogicalKeyboardKey.keyG);
      expect(at(controller), (1, 4), reason: 'wrapped to the first');
      expect(status(tester), '1 of 10');
    }, variant: macOS);

    testWidgets('a match below the visible area is scrolled into view', (
      tester,
    ) async {
      final long = '[\n${List.filled(300, '  1').join(',\n')},\n  "needle"\n]';
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MainWindow(
            pickJsonFile: () async => PickedFile(path: '/d/l.json', text: long),
          ),
        ),
      );
      await pressCmd(tester, LogicalKeyboardKey.keyO);
      await pressCmd(tester, LogicalKeyboardKey.keyF);
      await tester.enterText(field, 'needle');
      await tester.pumpAndSettle();
      final visible = tester
          .widget<DefaultCodeLineNumber>(find.byType(DefaultCodeLineNumber))
          .notifier
          .value!
          .paragraphs
          .map((p) => p.index);
      expect(visible, contains(301));
    }, variant: macOS);

    testWidgets('Esc closes the field and keeps the selection', (tester) async {
      final controller = await searchA(tester);
      await key(tester, LogicalKeyboardKey.enter);
      final selection = controller.selection;
      await key(tester, LogicalKeyboardKey.escape);
      expect(field, findsNothing);
      expect(controller.selection, selection);
    }, variant: macOS);
  });
}
