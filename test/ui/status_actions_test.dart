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

/// Wrap, Format and Minify pills in the Status Bar (#102).
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

  bool wraps(WidgetTester tester) =>
      tester.widget<CodeEditor>(textEditor).wordWrap!;

  Finder pill(String label) => find.descendant(
    of: find.byKey(const Key('statusBar')),
    matching: find.text(label),
  );

  testWidgets('the Wrap pill, View › Word Wrap and ⌥Z stay in sync', (
    tester,
  ) async {
    await openText(tester, '[1]');
    await tester.tap(pill('Wrap'));
    await tester.pumpAndSettle();
    expect(wraps(tester), isTrue);
    expect(checkmarks, [true], reason: 'the menu checkmark follows');

    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pumpAndSettle();
    expect(wraps(tester), isFalse);

    tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      windowChannel.name,
      windowChannel.codec.encodeMethodCall(
        const MethodCall('menu', 'wordWrap'),
      ),
      (_) {},
    );
    await tester.pumpAndSettle();
    expect(wraps(tester), isTrue);
    final selected = tester.widget<Material>(
      find.ancestor(of: pill('Wrap'), matching: find.byType(Material)).first,
    );
    expect(selected.color, isNot(Colors.transparent), reason: 'pill shows on');
    expect(checkmarks, [true, false, true]);
  }, variant: macOS);

  testWidgets('Format and Minify run the commands and undo in one step', (
    tester,
  ) async {
    await openText(tester, '{"a": [1, 2]}');
    final c = editorController(tester);
    await tester.tap(pill('Format'));
    await tester.pumpAndSettle();
    expect(c.text, '{\n  "a": [\n    1,\n    2\n  ]\n}');
    await tester.tap(pill('Minify'));
    await tester.pumpAndSettle();
    expect(c.text, '{"a":[1,2]}');
    await pressCmd(tester, LogicalKeyboardKey.keyZ);
    expect(c.text, '{\n  "a": [\n    1,\n    2\n  ]\n}');
  }, variant: macOS);
}
