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

final longLine =
    '{\n  "long": "${List.generate(200, (i) => 'w$i').join(' ')}",\n'
    '  "after": true\n}';

void main() {
  late List<bool> checkmarks;

  setUp(() {
    checkmarks = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(windowChannel, (call) async {
          if (call.method == 'setWordWrapChecked') {
            checkmarks.add(call.arguments as bool);
          }
          return null;
        });
  });

  Future<void> openLong(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MainWindow(
          pickJsonFile: () async =>
              PickedFile(path: '/d/a.json', text: longLine),
        ),
      ),
    );
    await pressCmd(tester, LogicalKeyboardKey.keyO);
  }

  bool wraps(WidgetTester tester) =>
      tester.widget<CodeEditor>(textEditor).wordWrap!;

  Future<void> optionZ(WidgetTester tester) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pumpAndSettle();
  }

  List<CodeLineRenderParagraph> visibleLines(WidgetTester tester) => tester
      .widget<DefaultCodeLineNumber>(find.byType(DefaultCodeLineNumber))
      .notifier
      .value!
      .paragraphs;

  testWidgets('off by default; long lines run past the pane', (tester) async {
    await openLong(tester);
    expect(wraps(tester), isFalse);
    final long = visibleLines(tester)[1];
    final short = visibleLines(tester)[2];
    expect(long.height, short.height, reason: 'one visual row each');
  }, variant: macOS);

  testWidgets('Opt+Z wraps long lines to the pane width and back', (
    tester,
  ) async {
    await openLong(tester);
    final text = editorController(tester).text;

    await optionZ(tester);
    expect(wraps(tester), isTrue);
    expect(checkmarks, [true]);
    final lines = visibleLines(tester);
    expect(
      lines[1].height,
      greaterThan(lines[2].height * 2),
      reason: 'the long line takes several rows',
    );
    expect(editorController(tester).text, text, reason: 'no "Ω" typed');

    await optionZ(tester);
    expect(wraps(tester), isFalse);
    expect(checkmarks, [true, false]);
  }, variant: macOS);

  testWidgets('line numbers count logical lines, once per wrapped line', (
    tester,
  ) async {
    await openLong(tester);
    await optionZ(tester);
    expect(visibleLines(tester).map((l) => l.index), [0, 1, 2, 3]);
  }, variant: macOS);

  testWidgets('View › Word Wrap toggles it too', (tester) async {
    await openLong(tester);
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      windowChannel.name,
      windowChannel.codec.encodeMethodCall(
        const MethodCall('menu', 'wordWrap'),
      ),
      (_) {},
    );
    await tester.pumpAndSettle();
    expect(wraps(tester), isTrue);
    expect(checkmarks, [true]);
  }, variant: macOS);
}
