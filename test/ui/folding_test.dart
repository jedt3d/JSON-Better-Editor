import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_better_editor/app/app.dart';
import 'package:json_better_editor/l10n/app_localizations.dart';
import 'package:json_better_editor/ui/file_access.dart';
import 'package:json_better_editor/ui/main_window.dart';
import 'package:material_ui/material_ui.dart';
import 'package:re_editor/re_editor.dart';

import 'editor_support.dart';

const text =
    '{\n'
    '  "a": {\n'
    '    "x": 1,\n'
    '    "y": [\n'
    '      2\n'
    '    ]\n'
    '  },\n'
    '  "b": true\n'
    '}';

late Map<String, String> files;

Future<void> openText(WidgetTester tester) async {
  files = {};
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MainWindow(
        pickJsonFile: () async =>
            const PickedFile(path: '/d/a.json', text: text),
        writeTextFile: (path, t) async => files[path] = t,
      ),
    ),
  );
  await pressCmd(tester, LogicalKeyboardKey.keyO);
  // The fold analysis runs in an isolate: wait for it in real time.
  for (var i = 0; i < 50 && chunks(tester).value.isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
  }
}

CodeChunkController chunks(WidgetTester tester) => tester
    .widget<DefaultCodeChunkIndicator>(find.byType(DefaultCodeChunkIndicator))
    .controller;

String documentTitle(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('documentTitle'))).data!;

void main() {
  testWidgets('every multi-line { or [ can fold, including its closing line', (
    tester,
  ) async {
    await openText(tester);
    expect(
      [for (final c in chunks(tester).value) (c.index, c.end)],
      [(0, 9), (1, 7), (3, 6)],
      reason: 'lines 1, 2 and 4 (1-based) open blocks',
    );
  }, variant: macOS);

  testWidgets('fold hides the block; unfold brings it back; text unchanged', (
    tester,
  ) async {
    await openText(tester);
    final controller = editorController(tester);

    chunks(tester).collapse(1);
    await tester.pumpAndSettle();
    expect(controller.codeLines.length, 4, reason: '"a" block is one line');
    expect(controller.codeLines[1].text, '  "a": {');
    expect(controller.codeLines[2].text, '  "b": true');
    expect(controller.text, text);
    expect(documentTitle(tester), 'a.json', reason: 'folding is not an edit');

    controller.expandChunk(1);
    await tester.pumpAndSettle();
    expect(controller.codeLines.length, 9);
    expect(controller.text, text);
  }, variant: macOS);

  testWidgets('Save writes the folded text too', (tester) async {
    await openText(tester);
    chunks(tester).collapse(1);
    await tester.pumpAndSettle();
    await pressCmd(tester, LogicalKeyboardKey.keyS);
    expect(files['/d/a.json'], '$text\n');
  }, variant: macOS);

  testWidgets('editing around a fold keeps the folded lines', (tester) async {
    await openText(tester);
    chunks(tester).collapse(1);
    await tester.pumpAndSettle();
    final controller = editorController(tester)
      ..selection = const CodeLineSelection.collapsed(index: 2, offset: 11);
    await tester.pump();
    await typeText(tester, 'X');
    expect(controller.text, text.replaceFirst('"b": true', '"b": trueX'));
    expect(documentTitle(tester), 'a.json — Edited');

    controller.expandChunk(1);
    await tester.pumpAndSettle();
    expect(controller.codeLines[2].text, '    "x": 1,');
  }, variant: macOS);

  testWidgets('clicking the gutter marker folds, clicking again unfolds', (
    tester,
  ) async {
    await openText(tester);
    final controller = editorController(tester);
    final indicator = find.byType(DefaultCodeChunkIndicator);
    final line2 = tester
        .widget<DefaultCodeChunkIndicator>(indicator)
        .notifier
        .value!
        .paragraphs
        .firstWhere((p) => p.index == 1);
    final at =
        tester.getTopLeft(indicator) +
        Offset(
          tester.getSize(indicator).width / 2,
          line2.top + line2.height / 2,
        );

    await tester.tapAt(at);
    await tester.pumpAndSettle();
    expect(controller.codeLines.length, 4);

    await tester.tapAt(at);
    await tester.pumpAndSettle();
    expect(controller.codeLines.length, 9);
    expect(controller.text, text);
  }, variant: macOS);

  testWidgets('edit, undo, then fold: still not edited', (tester) async {
    await openText(tester);
    final controller = editorController(tester)
      ..selection = const CodeLineSelection.collapsed(index: 7, offset: 11);
    await tester.pump();
    await typeText(tester, 'X');
    expect(documentTitle(tester), 'a.json — Edited');
    await pressCmd(tester, LogicalKeyboardKey.keyZ);
    expect(documentTitle(tester), 'a.json');
    chunks(tester).collapse(1);
    await tester.pumpAndSettle();
    expect(controller.codeLines.length, 4);
    expect(documentTitle(tester), 'a.json');
  }, variant: macOS);
}
