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
  final titles = <String>[];

  setUp(() {
    titles.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(windowChannel, (call) async {
          if (call.method == 'setTitle') titles.add(call.arguments as String);
          return null;
        });
  });

  Future<void> pumpApp(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MainWindow(
        pickJsonFile: () async =>
            const PickedFile(path: '/d/a.json', text: '[1]'),
      ),
    ),
  );

  String documentTitle(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('documentTitle'))).data!;

  testWidgets('New gives an editable Untitled document holding {}', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('New'));
    await tester.pumpAndSettle();

    expect(editorShowing('{}'), findsOneWidget);
    expect(documentTitle(tester), 'Untitled');
    expect(titles.last, 'Untitled');
  }, variant: macOS);

  testWidgets('Cmd+N replaces an open file with a new document', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip('Open'));
    await tester.pumpAndSettle();

    await pressCmd(tester, LogicalKeyboardKey.keyN);

    expect(editorShowing('{}'), findsOneWidget);
    expect(documentTitle(tester), 'Untitled');
  }, variant: macOS);

  testWidgets('New, type valid JSON: the document holds it', (tester) async {
    await pumpApp(tester);
    await pressCmd(tester, LogicalKeyboardKey.keyN);
    await tester.tap(textEditor);
    await tester.pumpAndSettle();
    final controller = editorController(tester)
      ..selection = const CodeLineSelection.collapsed(index: 0, offset: 1);
    await tester.pump();

    await typeText(tester, '"a": 1');

    expect(controller.text, '{"a": 1}');
    final parsed = parse(controller.text) as ParseSuccess;
    final root = parsed.document.root as JsonObject;
    expect(root.members.single.key, 'a');
    expect((root.members.single.value as JsonNumber).text, '1');
  }, variant: macOS);

  group('Save on an Untitled document (#29)', () {
    late Map<String, String> files;
    late List<String> asked;
    String? nextPath;

    Future<void> pumpSaving(WidgetTester tester) {
      files = {};
      asked = [];
      return tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MainWindow(
            chooseSavePath: (name) async {
              asked.add(name);
              return nextPath;
            },
            writeTextFile: (path, text) async => files[path] = text,
          ),
        ),
      );
    }

    testWidgets('Cmd+S opens the save panel; Cancel keeps it unsaved', (
      tester,
    ) async {
      nextPath = null;
      await pumpSaving(tester);
      await pressCmd(tester, LogicalKeyboardKey.keyN);

      await pressCmd(tester, LogicalKeyboardKey.keyS);

      expect(asked, ['Untitled']);
      expect(files, isEmpty);
      expect(documentTitle(tester), 'Untitled');
      expect(editorShowing('{}'), findsOneWidget);
    }, variant: macOS);

    testWidgets('after saving, the title is the file name and the next '
        'Cmd+S writes without a panel', (tester) async {
      nextPath = '/d/new.json';
      await pumpSaving(tester);
      await pressCmd(tester, LogicalKeyboardKey.keyN);

      await pressCmd(tester, LogicalKeyboardKey.keyS);
      expect(files['/d/new.json'], '{}\n');
      expect(documentTitle(tester), 'new.json');
      expect(titles.last, 'new.json');

      files.clear();
      await pressCmd(tester, LogicalKeyboardKey.keyS);
      expect(asked, ['Untitled'], reason: 'no second panel');
      expect(files['/d/new.json'], '{}\n');
    }, variant: macOS);
  });
}
