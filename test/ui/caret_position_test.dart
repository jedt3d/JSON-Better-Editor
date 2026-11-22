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

/// Caret position in the Status Bar (#100).
void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(windowChannel, (_) async => null);
  });

  final caret = find.byKey(const Key('caretPosition'));

  String caretText(WidgetTester tester) => tester
      .widget<Text>(find.descendant(of: caret, matching: find.byType(Text)))
      .data!;

  Future<CodeLineEditingController> openText(
    WidgetTester tester,
    String text,
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
    return editorController(tester);
  }

  testWidgets('Ln and Col follow the caret (1-based, characters)', (
    tester,
  ) async {
    final c = await openText(tester, '{\n  "😀": "ไทย"\n}');
    expect(caretText(tester), 'Ln 1, Col 1');
    c.selection = const CodeLineSelection.collapsed(index: 1, offset: 6);
    await tester.pumpAndSettle();
    expect(caretText(tester), 'Ln 2, Col 6', reason: 'the emoji is 1 char');
  }, variant: macOS);

  testWidgets('folded lines are counted in the line number', (tester) async {
    final c = await openText(tester, '[\n  {\n    "a": 1\n  },\n  2\n]');
    c.collapseChunk(1, 3);
    await tester.pumpAndSettle();
    c.selection = const CodeLineSelection.collapsed(index: 3, offset: 2);
    await tester.pumpAndSettle();
    expect(c.codeLines[3].text, '  2');
    expect(caretText(tester), 'Ln 5, Col 3');
  }, variant: macOS);

  testWidgets('a selection adds the number of selected characters', (
    tester,
  ) async {
    final c = await openText(tester, '["abc", "ไทย"]');
    c.selection = const CodeLineSelection(
      baseIndex: 0,
      baseOffset: 9,
      extentIndex: 0,
      extentOffset: 12,
    );
    await tester.pumpAndSettle();
    expect(caretText(tester), 'Ln 1, Col 13 (3 selected)');
  }, variant: macOS);

  testWidgets('clicking it opens Go to Line', (tester) async {
    await openText(tester, '[1]');
    await tester.tap(caret);
    await tester.pumpAndSettle();
    expect(find.text('Go to Line'), findsOneWidget);
  }, variant: macOS);
}
