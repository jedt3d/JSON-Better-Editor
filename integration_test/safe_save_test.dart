import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:json_better_editor/ui/file_access.dart';
import 'package:json_better_editor/ui/file_writer.dart';
import 'package:material_ui/material_ui.dart';

/// Safe save (#87) against the real macOS file system, through the app's
/// native `replaceFile`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  setUp(() async {
    // The native channel needs the app's window to exist.
    await Future<void>.delayed(Duration.zero);
    dir = Directory.systemTemp.createTempSync('jbe_safe_save');
  });
  tearDown(() {
    Process.runSync('chmod', ['-R', 'u+w', dir.path]);
    dir.deleteSync(recursive: true);
  });

  testWidgets('replaces the contents and keeps the permissions', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final file = File('${dir.path}/a.json')..writeAsStringSync('[1]\n');
    Process.runSync('chmod', ['640', file.path]);

    await const MacFileWriter().write(file.path, '[\n  2\n]\n');

    expect(file.readAsStringSync(), '[\n  2\n]\n');
    final mode = Process.runSync('stat', ['-f', '%Lp', file.path]).stdout;
    expect((mode as String).trim(), '640');
  });

  testWidgets('a new file is created', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final file = File('${dir.path}/new.json');
    await const MacFileWriter().write(file.path, '{}\n');
    expect(file.readAsStringSync(), '{}\n');
  });

  testWidgets('when the swap fails, the original is unchanged', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final file = File('${dir.path}/a.json')..writeAsStringSync('[1]\n');
    // A read-only folder: the file cannot be replaced.
    Process.runSync('chmod', ['555', dir.path]);

    await expectLater(
      const MacFileWriter().write(file.path, '[2]\n'),
      throwsA(isA<FileAccessException>()),
    );
    expect(file.readAsStringSync(), '[1]\n');
  });
}
