import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_better_editor/app/app.dart';

void main() {
  const windowChannel = MethodChannel('json_better_editor/window');
  final nativeTitles = <String>[];

  setUp(() {
    nativeTitles.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(windowChannel, (call) async {
      if (call.method == 'setTitle') nativeTitles.add(call.arguments as String);
      return null;
    });
  });

  testWidgets('window title is the English app title from the ARB file',
      (tester) async {
    await tester.pumpWidget(const JsonBetterEditorApp());

    expect(tester.widget<Title>(find.byType(Title)).title,
        'JSON Better Editor');
    expect(nativeTitles.last, 'JSON Better Editor');
  });

  testWidgets('uses Material 3 light and dark themes that follow the system',
      (tester) async {
    await tester.pumpWidget(const JsonBetterEditorApp());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.system);
    expect(app.theme!.useMaterial3, isTrue);
    expect(app.theme!.brightness, Brightness.light);
    expect(app.darkTheme!.useMaterial3, isTrue);
    expect(app.darkTheme!.brightness, Brightness.dark);
  });

  testWidgets('English is the only supported locale', (tester) async {
    await tester.pumpWidget(const JsonBetterEditorApp());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.supportedLocales, [const Locale('en')]);
  });
}
