import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_better_editor/app/app.dart';
import 'package:json_better_editor/l10n/app_localizations.dart';
import 'package:json_better_editor/ui/file_access.dart';
import 'package:json_better_editor/ui/main_window.dart';
import 'package:json_better_editor/ui/status_bar.dart';
import 'package:material_ui/material_ui.dart';
import 'package:re_editor/re_editor.dart';

import 'editor_support.dart';

const windowChannel = MethodChannel('json_better_editor/window');

void main() {
  late List<bool> menuTitles;

  setUp(() {
    menuTitles = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(windowChannel, (call) async {
          if (call.method == 'setStatusBarShown') {
            menuTitles.add(call.arguments as bool);
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
    await tester.pump(const Duration(milliseconds: 300));
  }

  String size(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('statusSize'))).data!;

  testWidgets('shows TEXT and the line count and UTF-8 size', (tester) async {
    await openText(tester, '{\n  "ไทย": "😀"\n}');
    expect(find.text('TEXT'), findsOneWidget);
    // '{' 1, '\n' 1, '  "ไทย": "😀"' 21 (ไทย 9 bytes, 😀 4), '\n' 1, '}' 1.
    expect(size(tester), '3 lines · 25 B');
  }, variant: macOS);

  testWidgets('updates after an edit (folded lines still count)', (
    tester,
  ) async {
    await openText(tester, '[\n  1,\n  2\n]');
    expect(size(tester), '4 lines · 12 B');
    final c = editorController(tester)
      ..selection = const CodeLineSelection.collapsed(index: 2, offset: 3)
      ..replaceSelection(',\n  3');
    await tester.pump(const Duration(milliseconds: 300));
    expect(size(tester), '5 lines · 17 B');
    c.collapseChunk(0, 4);
    await tester.pump(const Duration(milliseconds: 300));
    expect(size(tester), '5 lines · 17 B');
  }, variant: macOS);

  testWidgets('⌘/ and View › Hide Status Bar toggle it; the menu follows', (
    tester,
  ) async {
    await openText(tester, '[]');
    expect(find.byType(StatusBar), findsOneWidget);
    await pressCmd(tester, LogicalKeyboardKey.slash);
    expect(find.byType(StatusBar), findsNothing);
    expect(menuTitles, [false]);
    tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      windowChannel.name,
      windowChannel.codec.encodeMethodCall(
        const MethodCall('menu', 'statusBar'),
      ),
      (_) {},
    );
    await tester.pumpAndSettle();
    expect(find.byType(StatusBar), findsOneWidget);
    expect(menuTitles, [false, true]);
  }, variant: macOS);

  test('sizes read B, KB or MB', () {
    expect(formatSize(512), '512 B');
    expect(formatSize(4300), '4.2 KB');
    expect(formatSize(300 * 1024), '300 KB');
    expect(formatSize(5 * 1024 * 1024), '5.0 MB');
  });
}
