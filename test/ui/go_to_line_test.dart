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

/// 300 lines: an object with a 3-line nested block at lines 2–6.
final text = [
  '{',
  '  "inner": {',
  '    "a": 1,',
  '    "b": 2,',
  '    "c": 3',
  '  },',
  for (var i = 0; i < 292; i++) '  "k$i": $i,',
  '  "last": 0',
  '}',
].join('\n');

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(windowChannel, (_) async => null);
  });

  Future<CodeLineEditingController> openText(WidgetTester tester) async {
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
    return editorController(tester);
  }

  final field = find.byKey(const Key('goToLineField'));

  Future<void> goTo(WidgetTester tester, String typed) async {
    tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      windowChannel.name,
      windowChannel.codec.encodeMethodCall(
        const MethodCall('menu', 'goToLine'),
      ),
      (_) {},
    );
    await tester.pumpAndSettle();
    await tester.enterText(field, typed);
    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();
  }

  List<int> visible(WidgetTester tester) => [
    for (final p
        in tester
            .widget<DefaultCodeLineNumber>(find.byType(DefaultCodeLineNumber))
            .notifier
            .value!
            .paragraphs)
      p.index,
  ];

  testWidgets('goes to the start of a line and scrolls it into view', (
    tester,
  ) async {
    final c = await openText(tester);
    await goTo(tester, '250');
    expect(
      c.selection,
      const CodeLineSelection.collapsed(index: 249, offset: 0),
    );
    expect(visible(tester), contains(249));
  }, variant: macOS);

  testWidgets('a number past the end goes to the last line', (tester) async {
    final c = await openText(tester);
    await goTo(tester, '99999');
    expect(c.selection.extentIndex, 299);
  }, variant: macOS);

  testWidgets('only digits can be typed', (tester) async {
    await openText(tester);
    tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      windowChannel.name,
      windowChannel.codec.encodeMethodCall(
        const MethodCall('menu', 'goToLine'),
      ),
      (_) {},
    );
    await tester.pumpAndSettle();
    await tester.enterText(field, '1a2-b');
    expect(tester.widget<TextField>(field).controller!.text, '12');
  }, variant: macOS);

  testWidgets('a line inside a folded block unfolds it', (tester) async {
    final c = await openText(tester);
    c.collapseChunk(1, 6);
    await tester.pumpAndSettle();
    expect(c.codeLines.length, 296, reason: 'lines 3–6 folded');

    await goTo(tester, '4');
    expect(c.codeLines.length, 300);
    expect(c.selection, const CodeLineSelection.collapsed(index: 3, offset: 0));
    expect(c.codeLines[3].text, '    "b": 2,');
  }, variant: macOS);
}
