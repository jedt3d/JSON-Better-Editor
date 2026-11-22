import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:json_better_editor/app/app.dart';
import 'package:json_better_editor/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app launches on macOS and shows the main window',
      (tester) async {
    app.main();
    await tester.pumpAndSettle();

    expect(find.byType(JsonBetterEditorApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
