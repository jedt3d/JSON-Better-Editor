import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_better_editor/app/app.dart';
import 'package:json_better_editor/l10n/app_localizations.dart';
import 'package:json_better_editor/ui/file_access.dart';
import 'package:json_better_editor/ui/main_window.dart';
import 'package:material_ui/material_ui.dart';
import 'package:re_editor/re_editor.dart';

import 'editor_support.dart';

Future<void> openText(WidgetTester tester, String text) async {
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
}

/// [count] lines of a JSON array.
String lines(int count) => '[\n${List.filled(count - 2, '  1').join(',\n')}\n]';

final gutter = find.byType(DefaultCodeLineNumber);

void main() {
  testWidgets('the gutter shows a number for each visible line', (
    tester,
  ) async {
    await openText(tester, lines(5));
    final value = tester.widget<DefaultCodeLineNumber>(gutter).notifier.value!;
    expect(value.paragraphs.map((p) => p.index), [0, 1, 2, 3, 4]);
  }, variant: macOS);

  testWidgets('the gutter widens with the number of lines', (tester) async {
    await openText(tester, lines(50));
    final narrow = tester.getSize(gutter).width;
    await openText(tester, lines(100000));
    final wide = tester.getSize(gutter).width;
    expect(wide, greaterThan(narrow), reason: '6 digits need more room');
  }, variant: macOS);

  testWidgets('the gutter scrolls with the text', (tester) async {
    await openText(tester, lines(500));
    final controller = editorController(tester)
      ..selection = const CodeLineSelection.collapsed(index: 400, offset: 0)
      ..makeCursorVisible();
    await tester.pumpAndSettle();
    final value = tester.widget<DefaultCodeLineNumber>(gutter).notifier.value!;
    expect(value.paragraphs.map((p) => p.index), contains(400));
    expect(value.paragraphs.map((p) => p.index), isNot(contains(0)));
    expect(controller.selection.extentIndex, 400);
  }, variant: macOS);

  testWidgets("the caret's line number is the emphasised one", (tester) async {
    await openText(tester, lines(10));
    editorController(tester).selection = const CodeLineSelection.collapsed(
      index: 3,
      offset: 0,
    );
    await tester.pumpAndSettle();
    final value = tester.widget<DefaultCodeLineNumber>(gutter).notifier.value!;
    expect(value.focusedIndex, 3);
  }, variant: macOS);
}
