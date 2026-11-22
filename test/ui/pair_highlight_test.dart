import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_better_editor/app/app.dart';
import 'package:json_better_editor/l10n/app_localizations.dart';
import 'package:json_better_editor/ui/file_access.dart';
import 'package:json_better_editor/ui/main_window.dart';
import 'package:material_ui/material_ui.dart';
import 'package:re_editor/re_editor.dart';

import 'editor_support.dart';

final pairHighlight = find.byKey(const Key('pairHighlight'));

Future<void> openWithCaret(WidgetTester tester, String text, int column) async {
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
  editorController(tester).selection = CodeLineSelection.collapsed(
    index: 0,
    offset: column,
  );
  await tester.pumpAndSettle();
}

/// Each matched character gets a filled and an outlined box.
Matcher boxes(int count) {
  final pattern = paints;
  for (var i = 0; i < count * 2; i++) {
    pattern.rrect();
  }
  return pattern as Matcher;
}

void main() {
  testWidgets('caret next to a bracket boxes it and its pair', (tester) async {
    await openWithCaret(tester, '{"a": [1, 2]}', 7);
    expect(pairHighlight, boxes(2));
    expect(pairHighlight, isNot(boxes(3)));
  }, variant: macOS);

  testWidgets('caret inside a string boxes its two quotes', (tester) async {
    await openWithCaret(tester, '{"key": 1}', 3);
    expect(pairHighlight, boxes(2));
  }, variant: macOS);

  testWidgets('nothing to pair draws nothing', (tester) async {
    await openWithCaret(tester, '{"a": 12}', 7);
    expect(pairHighlight, isNot(paints..rrect()));
  }, variant: macOS);
}
