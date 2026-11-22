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

const text =
    '{\n' // 0
    '  "a": {\n' // 1
    '    "x": 1,\n' // 2
    '    "y": [\n' // 3
    '      2\n' // 4
    '    ]\n' // 5
    '  },\n' // 6
    '  "b": [\n' // 7
    '    3,\n' // 8
    '    4\n' // 9
    '  ],\n' // 10
    '  "c": true\n' // 11
    '}'; // 12

CodeChunkController chunks(WidgetTester tester) => tester
    .widget<DefaultCodeChunkIndicator>(find.byType(DefaultCodeChunkIndicator))
    .controller;

Future<void> openText(WidgetTester tester) async {
  // Wide enough for every Status Bar pill (a narrow window cuts them off).
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MainWindow(
        pickJsonFile: () async =>
            const PickedFile(path: '/d/a.json', text: text),
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

Finder pill(String label) => find.descendant(
  of: find.byKey(const Key('statusBar')),
  matching: find.text(label),
);

void menu(WidgetTester tester, String name) =>
    tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      windowChannel.name,
      windowChannel.codec.encodeMethodCall(MethodCall('menu', name)),
      (_) {},
    );

List<String> visible(CodeLineEditingController c) => [
  for (var i = 0; i < c.codeLines.length; i++) c.codeLines[i].text,
];

String documentTitle(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('documentTitle'))).data!;

/// Fold All / Unfold All from the Status Bar and the View menu (#103).
void main() {
  testWidgets('Fold all folds the blocks inside the root; Unfold all opens '
      'everything, nested folds too', (tester) async {
    await openText(tester);
    final c = editorController(tester);
    // A nested block folded by hand first.
    chunks(tester).collapse(3);
    await tester.pumpAndSettle();

    await tester.tap(pill('Fold all'));
    await tester.pumpAndSettle();
    expect(visible(c), ['{', '  "a": {', '  "b": [', '  "c": true', '}']);
    expect(c.text, text, reason: 'folding never changes the text');
    expect(documentTitle(tester), 'a.json', reason: 'not an edit');
    expect(
      [for (final k in chunks(tester).value) (k.index, k.end)],
      contains((0, 5)),
      reason: 'the root marker still covers the folded document',
    );

    await tester.tap(pill('Unfold all'));
    await tester.pumpAndSettle();
    expect(visible(c), text.split('\n'));
  }, variant: macOS);

  testWidgets('View menu items do the same; the caret stays visible; '
      'neither is an undo step', (tester) async {
    await openText(tester);
    final c = editorController(tester);
    c.selection = const CodeLineSelection.collapsed(index: 4, offset: 6);

    menu(tester, 'foldAll');
    await tester.pumpAndSettle();
    expect(c.codeLines.length, 5);
    expect(c.selection.extentIndex, 1, reason: 'caret moves to the fold line');

    await pressCmd(tester, LogicalKeyboardKey.keyZ);
    expect(c.codeLines.length, 5, reason: 'Undo does not unfold');
    expect(c.text, text);

    menu(tester, 'unfoldAll');
    await tester.pumpAndSettle();
    expect(c.codeLines.length, 13);
    expect(c.text, text);
  }, variant: macOS);
}
