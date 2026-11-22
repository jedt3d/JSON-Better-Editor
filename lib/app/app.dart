import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../ui/main_window.dart';
import 'theme.dart';
import 'window_title.dart';

/// Root widget of JSON Better Editor.
class JsonBetterEditorApp extends StatelessWidget {
  const JsonBetterEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) {
        final title = AppLocalizations.of(context)!.appTitle;
        setWindowTitle(title);
        return title;
      },
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const MainWindow(),
    );
  }
}
