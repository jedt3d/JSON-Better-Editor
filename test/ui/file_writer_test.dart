import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_better_editor/ui/file_access.dart';
import 'package:json_better_editor/ui/file_writer.dart';

const channel = MethodChannel('json_better_editor/window');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('MacFileWriter asks the native side to replace the file', () async {
    MethodCall? sent;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          sent = call;
          return null;
        });
    await const MacFileWriter().write('/d/a.json', '[1]\n');
    expect(sent?.method, 'replaceFile');
    expect(sent?.arguments, {'path': '/d/a.json', 'text': '[1]\n'});
  });

  test('a native failure becomes FileAccessException with the OS message', () {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (_) async => throw PlatformException(
            code: 'write',
            message: 'You don’t have permission.',
          ),
        );
    expect(
      const MacFileWriter().write('/d/a.json', '[1]'),
      throwsA(
        isA<FileAccessException>()
            .having((e) => e.path, 'path', '/d/a.json')
            .having((e) => e.osMessage, 'osMessage', contains('permission')),
      ),
    );
  });
}
