// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'JSON Better Editor';

  @override
  String get toolbarNew => 'New';

  @override
  String get toolbarOpen => 'Open';

  @override
  String get toolbarSearch => 'Search';

  @override
  String get toolbarLayoutText => 'Text only';

  @override
  String get toolbarLayoutNode => 'Node only';

  @override
  String get toolbarLayoutSplit => 'Split view';

  @override
  String get toolbarLanguage => 'Language';

  @override
  String get toolbarTheme => 'Theme';

  @override
  String get toolbarSettings => 'Settings';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get emptyState => 'Open a JSON file';

  @override
  String openFailedTitle(String fileName) {
    return 'Can\'t open $fileName';
  }

  @override
  String invalidJsonPosition(int line, int column, String message) {
    return 'Line $line, column $column: $message';
  }

  @override
  String get fileNotText => 'The file is not UTF-8 text.';

  @override
  String get ok => 'OK';

  @override
  String get openFailed => 'Can\'t open the file';

  @override
  String saveFailedTitle(String fileName) {
    return 'Can\'t save $fileName';
  }

  @override
  String get saveFailed => 'Can\'t save the file';

  @override
  String get untitled => 'Untitled';

  @override
  String editedTitle(String fileName) {
    return '$fileName — Edited';
  }

  @override
  String unsavedTitle(String fileName) {
    return 'Do you want to save the changes made to “$fileName”?';
  }

  @override
  String get unsavedMessage =>
      'Your changes will be lost if you don\'t save them.';

  @override
  String get save => 'Save';

  @override
  String get dontSave => 'Don\'t Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get unknownError => 'An unknown error occurred.';
}
