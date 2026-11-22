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

void main() {
  late List<MethodCall> native;
  late Map<String, String> files;

  setUp(() {
    native = [];
    files = {'/d/a.json': '[1]', '/d/b.json': '[2]'};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(windowChannel, (call) async {
          native.add(call);
          return null;
        });
  });

  Future<void> openEdited(WidgetTester tester) async {
    var next = '/d/a.json';
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MainWindow(
          pickJsonFile: () async {
            final path = next;
            next = '/d/b.json';
            return PickedFile(path: path, text: files[path]!);
          },
          chooseSavePath: (_) async => null,
          writeTextFile: (path, text) async => files[path] = text,
        ),
      ),
    );
    await pressCmd(tester, LogicalKeyboardKey.keyO);
    await tester.tap(textEditor);
    await tester.pumpAndSettle();
    editorController(tester).selection = const CodeLineSelection.collapsed(
      index: 0,
      offset: 2,
    );
    await tester.pump();
    await typeText(tester, ', 3');
  }

  String documentTitle(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('documentTitle'))).data!;

  bool? lastEditedSent() =>
      native.lastWhere((c) => c.method == 'setEdited').arguments as bool;

  /// Sends the native close/quit request; the answer arrives once a
  /// prompt (if any) is answered.
  Future<bool? Function()> requestClose(WidgetTester tester) async {
    bool? answer;
    tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      windowChannel.name,
      windowChannel.codec.encodeMethodCall(const MethodCall('confirmClose')),
      (data) => answer = windowChannel.codec.decodeEnvelope(data!) as bool?,
    );
    await tester.pumpAndSettle();
    return () => answer;
  }

  testWidgets('an edit marks the window; Save clears the mark', (tester) async {
    await openEdited(tester);

    expect(documentTitle(tester), 'a.json — Edited');
    expect(lastEditedSent(), isTrue);

    await pressCmd(tester, LogicalKeyboardKey.keyS);
    expect(documentTitle(tester), 'a.json');
    expect(lastEditedSent(), isFalse);
  }, variant: macOS);

  testWidgets('undoing back to the saved text clears the mark', (tester) async {
    await openEdited(tester);
    await pressCmd(tester, LogicalKeyboardKey.keyZ);
    expect(editorController(tester).text, '[1]');
    expect(documentTitle(tester), 'a.json');
  }, variant: macOS);

  group('New and Open with unsaved changes', () {
    for (final (name, press) in [
      ('New', () => LogicalKeyboardKey.keyN),
      ('Open', () => LogicalKeyboardKey.keyO),
    ]) {
      testWidgets('$name → Cancel keeps everything as it was', (tester) async {
        await openEdited(tester);
        await pressCmd(tester, press());

        expect(
          find.text('Do you want to save the changes made to “a.json”?'),
          findsOneWidget,
        );
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(editorController(tester).text, '[1, 3]');
        expect(documentTitle(tester), 'a.json — Edited');
        expect(files['/d/a.json'], '[1]');
      }, variant: macOS);

      testWidgets("$name → Don't Save drops the edits", (tester) async {
        await openEdited(tester);
        await pressCmd(tester, press());
        await tester.tap(find.text("Don't Save"));
        await tester.pumpAndSettle();

        expect(files['/d/a.json'], '[1]');
        expect(documentTitle(tester), name == 'New' ? 'Untitled' : 'b.json');
      }, variant: macOS);

      testWidgets('$name → Save (the default button) writes first', (
        tester,
      ) async {
        await openEdited(tester);
        await pressCmd(tester, press());
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        expect(files['/d/a.json'], '[\n  1,\n  3\n]\n');
        expect(documentTitle(tester), name == 'New' ? 'Untitled' : 'b.json');
      }, variant: macOS);
    }
  });

  group('Close and Quit (native request)', () {
    testWidgets('with no edits it may close at once', (tester) async {
      await openEdited(tester);
      await pressCmd(tester, LogicalKeyboardKey.keyS);
      final answer = await requestClose(tester);
      expect(answer(), isTrue);
      expect(find.byType(AlertDialog), findsNothing);
    }, variant: macOS);

    for (final (button, closes) in [
      ('Cancel', false),
      ("Don't Save", true),
      ('Save', true),
    ]) {
      testWidgets('$button answers $closes', (tester) async {
        await openEdited(tester);
        final answer = await requestClose(tester);
        await tester.tap(find.text(button));
        await tester.pumpAndSettle();

        expect(answer(), closes);
        expect(
          files['/d/a.json'],
          button == 'Save' ? '[\n  1,\n  3\n]\n' : '[1]',
        );
      }, variant: macOS);
    }
  });
}
