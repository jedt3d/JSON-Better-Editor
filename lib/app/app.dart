import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import '../ui/main_window.dart';
import 'theme.dart';
import 'native_window.dart';

/// App strings plus Material, Cupertino and widgets localizations from
/// material_ui (the generated AppLocalizations.localizationsDelegates still
/// points at the deprecated flutter_localizations classes).
const appLocalizationsDelegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  ...GlobalMaterialLocalizations.delegates,
];

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
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const MainWindow(),
    );
  }
}
