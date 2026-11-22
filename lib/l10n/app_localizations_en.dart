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
  String get searchHint => 'Search keys and values';

  @override
  String searchCount(int current, int total) {
    return '$current of $total';
  }

  @override
  String get searchNoResults => 'No results';

  @override
  String get searchNext => 'Next match (⌘G)';

  @override
  String get searchPrevious => 'Previous match (⇧⌘G)';

  @override
  String get searchClose => 'Close search';

  @override
  String get validateValid => 'Valid JSON';

  @override
  String get validateValidMessage => 'The document is valid JSON.';

  @override
  String get validateInvalid => 'Invalid JSON';

  @override
  String get goToLineTitle => 'Go to Line';

  @override
  String goToLineHint(int count) {
    return 'Line number (1–$count)';
  }

  @override
  String get goToLineGo => 'Go';

  @override
  String fileChangedTitle(String fileName) {
    return '“$fileName” was changed by another program';
  }

  @override
  String get fileChangedMessage =>
      'Reload it from disk, or keep the version shown here?';

  @override
  String get fileChangedDropEdits =>
      'Reloading it drops your unsaved changes. Reload it from disk, or keep your version?';

  @override
  String get reload => 'Reload';

  @override
  String get keepMine => 'Keep Mine';

  @override
  String fileDeletedTitle(String fileName) {
    return '“$fileName” was moved or deleted';
  }

  @override
  String get fileDeletedMessage =>
      'The document stays open. Save writes it again.';

  @override
  String overwriteChangedTitle(String fileName) {
    return '“$fileName” changed on disk since you opened it';
  }

  @override
  String get overwriteChangedMessage =>
      'Saving replaces the other program\'s changes.';

  @override
  String get overwrite => 'Overwrite';

  @override
  String get recentMissing =>
      'The file is no longer there. It was removed from Open Recent.';

  @override
  String get statusPaneText => 'TEXT';

  @override
  String statusSize(int lines, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      lines,
      locale: localeName,
      other: '$lines lines',
      one: '1 line',
    );
    return '$_temp0 · $size';
  }

  @override
  String get statusValid => '✓ Valid JSON';

  @override
  String statusInvalid(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count errors',
      one: '1 error',
    );
    return '✗ Invalid JSON · $_temp0';
  }

  @override
  String get statusNotChecked => 'Not checked since edit';

  @override
  String get statusValidateTooltip => 'Validate JSON now';

  @override
  String statusCaret(int line, int column) {
    return 'Ln $line, Col $column';
  }

  @override
  String statusCaretSelected(String position, int count) {
    return '$position ($count selected)';
  }

  @override
  String get statusShowErrorsTooltip => 'Show the errors';

  @override
  String get errorsLocation => 'Location';

  @override
  String get errorsMessage => 'Error message';

  @override
  String errorsAt(int line, int column) {
    return 'Line $line, Col $column';
  }

  @override
  String get statusWrap => 'Wrap';

  @override
  String get statusFormat => 'Format';

  @override
  String get statusMinify => 'Minify';

  @override
  String get statusFoldAll => 'Fold all';

  @override
  String get statusUnfoldAll => 'Unfold all';

  @override
  String get lineEndingLf => 'LF (macOS, Linux)';

  @override
  String get lineEndingCrlf => 'CRLF (Windows)';

  @override
  String get unknownError => 'An unknown error occurred.';
}
