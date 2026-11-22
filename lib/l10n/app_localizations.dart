import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// Application name, shown as the window title.
  ///
  /// In en, this message translates to:
  /// **'JSON Better Editor'**
  String get appTitle;

  /// Toolbar tooltip: new document.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get toolbarNew;

  /// Toolbar tooltip: open a .json file.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get toolbarOpen;

  /// Toolbar tooltip: search keys and values.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get toolbarSearch;

  /// Toolbar tooltip: show only the Text pane.
  ///
  /// In en, this message translates to:
  /// **'Text only'**
  String get toolbarLayoutText;

  /// Toolbar tooltip: show only the Node pane.
  ///
  /// In en, this message translates to:
  /// **'Node only'**
  String get toolbarLayoutNode;

  /// Toolbar tooltip: show Text and Node side by side.
  ///
  /// In en, this message translates to:
  /// **'Split view'**
  String get toolbarLayoutSplit;

  /// Toolbar tooltip: switch UI language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get toolbarLanguage;

  /// Toolbar tooltip: switch light/dark theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get toolbarTheme;

  /// Toolbar tooltip: open settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get toolbarSettings;

  /// Message for toolbar buttons that are not built yet.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// Shown in the content area when no document is loaded.
  ///
  /// In en, this message translates to:
  /// **'Open a JSON file'**
  String get emptyState;

  /// Error dialog title when a file cannot be opened.
  ///
  /// In en, this message translates to:
  /// **'Can\'t open {fileName}'**
  String openFailedTitle(String fileName);

  /// Where the JSON is invalid. message is the parser's English message.
  ///
  /// In en, this message translates to:
  /// **'Line {line}, column {column}: {message}'**
  String invalidJsonPosition(int line, int column, String message);

  /// Error when the chosen file cannot be decoded as UTF-8.
  ///
  /// In en, this message translates to:
  /// **'The file is not UTF-8 text.'**
  String get fileNotText;

  /// Button that closes a dialog.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Error dialog title when the open panel itself fails.
  ///
  /// In en, this message translates to:
  /// **'Can\'t open the file'**
  String get openFailed;

  /// Error dialog title when a file cannot be written.
  ///
  /// In en, this message translates to:
  /// **'Can\'t save {fileName}'**
  String saveFailedTitle(String fileName);

  /// Error dialog title when the save panel itself fails.
  ///
  /// In en, this message translates to:
  /// **'Can\'t save the file'**
  String get saveFailed;

  /// Title of a new document that has not been saved yet.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get untitled;

  /// Document title while it has unsaved changes (macOS style).
  ///
  /// In en, this message translates to:
  /// **'{fileName} — Edited'**
  String editedTitle(String fileName);

  /// Unsaved-changes prompt title.
  ///
  /// In en, this message translates to:
  /// **'Do you want to save the changes made to “{fileName}”?'**
  String unsavedTitle(String fileName);

  /// Unsaved-changes prompt body.
  ///
  /// In en, this message translates to:
  /// **'Your changes will be lost if you don\'t save them.'**
  String get unsavedMessage;

  /// Button: save the document.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Button: discard unsaved changes.
  ///
  /// In en, this message translates to:
  /// **'Don\'t Save'**
  String get dontSave;

  /// Button: cancel the action.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Placeholder in the search field.
  ///
  /// In en, this message translates to:
  /// **'Search keys and values'**
  String get searchHint;

  /// Which match is selected, e.g. 2 of 7.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String searchCount(int current, int total);

  /// Shown when the search text is not found.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get searchNoResults;

  /// Tooltip of the next-match button.
  ///
  /// In en, this message translates to:
  /// **'Next match (⌘G)'**
  String get searchNext;

  /// Tooltip of the previous-match button.
  ///
  /// In en, this message translates to:
  /// **'Previous match (⇧⌘G)'**
  String get searchPrevious;

  /// Tooltip of the button that closes the search field.
  ///
  /// In en, this message translates to:
  /// **'Close search'**
  String get searchClose;

  /// Title of the Validate JSON result when the text is valid.
  ///
  /// In en, this message translates to:
  /// **'Valid JSON'**
  String get validateValid;

  /// Body of the Validate JSON result when the text is valid.
  ///
  /// In en, this message translates to:
  /// **'The document is valid JSON.'**
  String get validateValidMessage;

  /// Title of the Validate JSON result when the text has an error.
  ///
  /// In en, this message translates to:
  /// **'Invalid JSON'**
  String get validateInvalid;

  /// Title of the Go to Line dialog.
  ///
  /// In en, this message translates to:
  /// **'Go to Line'**
  String get goToLineTitle;

  /// Placeholder in the Go to Line field.
  ///
  /// In en, this message translates to:
  /// **'Line number (1–{count})'**
  String goToLineHint(int count);

  /// Button that moves to the line.
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get goToLineGo;

  /// Title when the open file changed on disk.
  ///
  /// In en, this message translates to:
  /// **'“{fileName}” was changed by another program'**
  String fileChangedTitle(String fileName);

  /// Body when the open file changed on disk and there are no unsaved edits.
  ///
  /// In en, this message translates to:
  /// **'Reload it from disk, or keep the version shown here?'**
  String get fileChangedMessage;

  /// Body when the open file changed on disk and there are unsaved edits.
  ///
  /// In en, this message translates to:
  /// **'Reloading it drops your unsaved changes. Reload it from disk, or keep your version?'**
  String get fileChangedDropEdits;

  /// Button: read the file again from disk.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get reload;

  /// Button: keep the version shown in the editor.
  ///
  /// In en, this message translates to:
  /// **'Keep Mine'**
  String get keepMine;

  /// Title when the open file is no longer on disk.
  ///
  /// In en, this message translates to:
  /// **'“{fileName}” was moved or deleted'**
  String fileDeletedTitle(String fileName);

  /// Body when the open file is no longer on disk.
  ///
  /// In en, this message translates to:
  /// **'The document stays open. Save writes it again.'**
  String get fileDeletedMessage;

  /// Title when saving over a file that another program changed.
  ///
  /// In en, this message translates to:
  /// **'“{fileName}” changed on disk since you opened it'**
  String overwriteChangedTitle(String fileName);

  /// Body when saving over a file that another program changed.
  ///
  /// In en, this message translates to:
  /// **'Saving replaces the other program\'s changes.'**
  String get overwriteChangedMessage;

  /// Button: save over the changed file.
  ///
  /// In en, this message translates to:
  /// **'Overwrite'**
  String get overwrite;

  /// Error body when an Open Recent entry points to a missing file.
  ///
  /// In en, this message translates to:
  /// **'The file is no longer there. It was removed from Open Recent.'**
  String get recentMissing;

  /// Status Bar label for the Text pane.
  ///
  /// In en, this message translates to:
  /// **'TEXT'**
  String get statusPaneText;

  /// Status Bar: number of lines and document size, e.g. 120 lines · 4.2 KB.
  ///
  /// In en, this message translates to:
  /// **'{lines, plural, =1{1 line} other{{lines} lines}} · {size}'**
  String statusSize(int lines, String size);

  /// Status Bar: the last check found no error.
  ///
  /// In en, this message translates to:
  /// **'✓ Valid JSON'**
  String get statusValid;

  /// Status Bar: the last check found errors.
  ///
  /// In en, this message translates to:
  /// **'✗ Invalid JSON · {count, plural, =1{1 error} other{{count} errors}}'**
  String statusInvalid(int count);

  /// Status Bar: the text changed since the last check.
  ///
  /// In en, this message translates to:
  /// **'Not checked since edit'**
  String get statusNotChecked;

  /// Tooltip of the Status Bar item when the text was not checked since an edit.
  ///
  /// In en, this message translates to:
  /// **'Validate JSON now'**
  String get statusValidateTooltip;

  /// Status Bar: caret line and column, 1-based.
  ///
  /// In en, this message translates to:
  /// **'Ln {line}, Col {column}'**
  String statusCaret(int line, int column);

  /// Status Bar: caret position with the number of selected characters.
  ///
  /// In en, this message translates to:
  /// **'{position} ({count} selected)'**
  String statusCaretSelected(String position, int count);

  /// Tooltip of the Status Bar item when the JSON is invalid.
  ///
  /// In en, this message translates to:
  /// **'Show the errors'**
  String get statusShowErrorsTooltip;

  /// Column header in the error list.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get errorsLocation;

  /// Column header in the error list.
  ///
  /// In en, this message translates to:
  /// **'Error message'**
  String get errorsMessage;

  /// Where an error is, in the error list.
  ///
  /// In en, this message translates to:
  /// **'Line {line}, Col {column}'**
  String errorsAt(int line, int column);

  /// Dialog body when the system gives no error message.
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred.'**
  String get unknownError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
