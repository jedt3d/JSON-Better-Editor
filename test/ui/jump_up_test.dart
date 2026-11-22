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

/// Fork patch 1 (packages/re_editor/JBE_CHANGES.md, #71): a long jump up
/// lands on the right lines, with and without word wrap.
void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(windowChannel, (_) async => null);
  });

  /// 3,000 lines; every 7th holds a string long enough to wrap.
  final text = [
    '[',
    for (var i = 0; i < 2998; i++)
      i % 7 == 0 ? '  "${'long ' * 60}$i",' : '  $i,',
    '  0',
    ']',
  ].join('\n');

  Future<CodeLineEditingController> openLong(
    WidgetTester tester, {
    required bool wrap,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MainWindow(
          pickJsonFile: () async => PickedFile(path: '/d/l.json', text: text),
        ),
      ),
    );
    await pressCmd(tester, LogicalKeyboardKey.keyO);
    if (wrap) {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pumpAndSettle();
    }
    return editorController(tester);
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

  Future<void> jumpTo(
    WidgetTester tester,
    CodeLineEditingController c,
    int line,
  ) async {
    c
      ..selection = CodeLineSelection.collapsed(index: line, offset: 0)
      ..makeCursorVisible();
    await tester.pumpAndSettle();
  }

  for (final wrap in [false, true]) {
    final mode = wrap ? 'word wrap on' : 'word wrap off';

    testWidgets('$mode: end → top shows the first lines', (tester) async {
      final c = await openLong(tester, wrap: wrap);
      await jumpTo(tester, c, c.codeLines.length - 1);
      expect(visible(tester), contains(c.codeLines.length - 1));
      await jumpTo(tester, c, 0);
      expect(visible(tester).first, 0);
    }, variant: macOS);

    testWidgets('$mode: end → middle shows the target line', (tester) async {
      final c = await openLong(tester, wrap: wrap);
      await jumpTo(tester, c, c.codeLines.length - 1);
      await jumpTo(tester, c, 1500);
      expect(visible(tester), contains(1500));
      await jumpTo(tester, c, 1501);
      expect(visible(tester), contains(1501), reason: 'stays in place');
    }, variant: macOS);
  }
}
