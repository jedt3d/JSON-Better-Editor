import 'package:flutter/material.dart';

/// Root widget of JSON Better Editor.
class JsonBetterEditorApp extends StatelessWidget {
  const JsonBetterEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'JSON Better Editor',
      home: Scaffold(),
    );
  }
}
