import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_better_editor/app/app.dart';

void main() {
  testWidgets('app starts with an empty window titled JSON Better Editor',
      (tester) async {
    await tester.pumpWidget(const JsonBetterEditorApp());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, 'JSON Better Editor');
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
