import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_better_editor/app/app.dart';
import 'package:json_better_editor/document/json_document.dart';
import 'package:json_better_editor/l10n/app_localizations.dart';
import 'package:json_better_editor/ui/file_access.dart';
import 'package:json_better_editor/ui/main_window.dart';
import 'package:material_ui/material_ui.dart';
import 'package:re_editor/re_editor.dart';

import 'editor_support.dart';

const windowChannel = MethodChannel('json_better_editor/window');

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(windowChannel, (_) async => null);
  });

  Future<CodeLineEditingController> openWith(
    WidgetTester tester,
    String valid,
    String edited,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MainWindow(
          pickJsonFile: () async => PickedFile(path: '/d/a.json', text: valid),
        ),
      ),
    );
    await pressCmd(tester, LogicalKeyboardKey.keyO);
    final c = editorController(tester)..text = edited;
    await tester.pumpAndSettle();
    return c;
  }

  Future<void> validate(WidgetTester tester) async {
    // Not awaited: the request finishes only when its dialog is closed.
    tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      windowChannel.name,
      windowChannel.codec.encodeMethodCall(
        const MethodCall('menu', 'validate'),
      ),
      (_) {},
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a valid document says "Valid JSON"', (tester) async {
    await openWith(tester, '[1]', '{\n  "a": [1, 2]\n}');
    await validate(tester);
    expect(find.text('Valid JSON'), findsOneWidget);
  }, variant: macOS);

  testWidgets('an error in the middle reports it and moves the caret there', (
    tester,
  ) async {
    final c = await openWith(tester, '[1]', '{\n  "a": [1 2],\n  "b": 3\n}');
    await validate(tester);
    expect(find.text('Invalid JSON'), findsOneWidget);
    expect(find.textContaining('Line 2, column 11'), findsOneWidget);
    expect(
      c.selection,
      const CodeLineSelection.collapsed(index: 1, offset: 10),
    );
  }, variant: macOS);

  testWidgets('an error at the end of the file', (tester) async {
    final c = await openWith(tester, '[1]', '{\n  "a": 1');
    await validate(tester);
    expect(find.textContaining('Line 2, column 9'), findsOneWidget);
    expect(find.textContaining('Unexpected end of input'), findsOneWidget);
    expect(c.selection.extentIndex, 1);
    expect(c.selection.extentOffset, 8);
  }, variant: macOS);

  test('columns count characters; the caret offset counts UTF-16 units', () {
    expect(utf16Column('a😀b', 3), 3, reason: 'the emoji is 2 units');
    expect(utf16Column('abc', 4), 3, reason: 'end of line');
  });
}
