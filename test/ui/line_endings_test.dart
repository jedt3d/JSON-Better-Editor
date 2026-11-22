import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_better_editor/app/app.dart';
import 'package:json_better_editor/document/line_endings.dart';
import 'package:json_better_editor/l10n/app_localizations.dart';
import 'package:json_better_editor/ui/file_access.dart';
import 'package:json_better_editor/ui/main_window.dart';
import 'package:material_ui/material_ui.dart';

import 'editor_support.dart';

const windowChannel = MethodChannel('json_better_editor/window');

void main() {
  group('detect', () {
    test('LF, CRLF and CR files', () {
      expect(LineEnding.detect('{\n"a": 1\n}\n'), LineEnding.lf);
      expect(LineEnding.detect('{\r\n"a": 1\r\n}\r\n'), LineEnding.crlf);
      expect(LineEnding.detect('{\r"a": 1\r}'), LineEnding.cr);
    });

    test('mixed: the most common one', () {
      expect(LineEnding.detect('a\r\nb\r\nc\nd'), LineEnding.crlf);
      expect(LineEnding.detect('a\nb\nc\r\nd'), LineEnding.lf);
    });

    test('no line break: the OS default (LF on macOS)', () {
      expect(LineEnding.detect('{"a": 1}'), LineEnding.lf);
    });
  });

  group('open and save', () {
    late Map<String, String> files;

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(windowChannel, (_) async => null);
    });

    Future<void> openAndSave(WidgetTester tester, String source) async {
      files = {'/d/a.json': source};
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MainWindow(
            pickJsonFile: () async =>
                PickedFile(path: '/d/a.json', text: files['/d/a.json']!),
            writeTextFile: (path, text) async => files[path] = text,
            fileModifiedTime: (_) async => null,
          ),
        ),
      );
      await pressCmd(tester, LogicalKeyboardKey.keyO);
      expect(editorController(tester).text, isNot(contains('\r')));
      await pressCmd(tester, LogicalKeyboardKey.keyS);
    }

    testWidgets('an LF file is saved with LF', (tester) async {
      await openAndSave(tester, '{\n"a": 1\n}\n');
      expect(files['/d/a.json'], '{\n  "a": 1\n}\n');
    }, variant: macOS);

    testWidgets('a CRLF file is edited with LF and saved with CRLF', (
      tester,
    ) async {
      await openAndSave(tester, '{\r\n"a": [1, 2]\r\n}\r\n');
      expect(
        files['/d/a.json'],
        '{\r\n  "a": [\r\n    1,\r\n    2\r\n  ]\r\n}\r\n',
      );
    }, variant: macOS);

    testWidgets('a mixed file is saved with its most common ending', (
      tester,
    ) async {
      await openAndSave(tester, '{\r\n"a": 1,\r\n"b": 2\n}\r\n');
      expect(files['/d/a.json'], '{\r\n  "a": 1,\r\n  "b": 2\r\n}\r\n');
    }, variant: macOS);
  });
}
