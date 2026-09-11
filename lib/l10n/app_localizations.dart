import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'FluxLab'**
  String get appTitle;

  /// No description provided for @chooseModule.
  ///
  /// In en, this message translates to:
  /// **'Developer Testing Workbench for API, socket, serial, terminal, payload, and simulator workflows.'**
  String get chooseModule;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @vietnamese.
  ///
  /// In en, this message translates to:
  /// **'Tiếng Việt'**
  String get vietnamese;

  /// No description provided for @carParkingTitle.
  ///
  /// In en, this message translates to:
  /// **'CarParking Device Gateway Simulator'**
  String get carParkingTitle;

  /// No description provided for @carParkingShort.
  ///
  /// In en, this message translates to:
  /// **'CarParking'**
  String get carParkingShort;

  /// No description provided for @carParkingDescription.
  ///
  /// In en, this message translates to:
  /// **'Device Gateway TCP simulator for CarParking_Techpro_Client.'**
  String get carParkingDescription;

  /// No description provided for @tcpLabTitle.
  ///
  /// In en, this message translates to:
  /// **'TCP Socket Lab'**
  String get tcpLabTitle;

  /// No description provided for @tcpLabShort.
  ///
  /// In en, this message translates to:
  /// **'TCP Lab'**
  String get tcpLabShort;

  /// No description provided for @tcpLabDescription.
  ///
  /// In en, this message translates to:
  /// **'Generic TCP client/server workspace.'**
  String get tcpLabDescription;

  /// No description provided for @webSocketTitle.
  ///
  /// In en, this message translates to:
  /// **'WebSocket Lab'**
  String get webSocketTitle;

  /// No description provided for @webSocketShort.
  ///
  /// In en, this message translates to:
  /// **'WebSocket'**
  String get webSocketShort;

  /// No description provided for @webSocketDescription.
  ///
  /// In en, this message translates to:
  /// **'WebSocket send/receive test bench.'**
  String get webSocketDescription;

  /// No description provided for @serialTitle.
  ///
  /// In en, this message translates to:
  /// **'Serial/COM Lab'**
  String get serialTitle;

  /// No description provided for @serialShort.
  ///
  /// In en, this message translates to:
  /// **'Serial'**
  String get serialShort;

  /// No description provided for @serialDescription.
  ///
  /// In en, this message translates to:
  /// **'Desktop serial-port test bench.'**
  String get serialDescription;

  /// No description provided for @bridgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Protocol Bridge'**
  String get bridgeTitle;

  /// No description provided for @bridgeShort.
  ///
  /// In en, this message translates to:
  /// **'Bridge'**
  String get bridgeShort;

  /// No description provided for @bridgeDescription.
  ///
  /// In en, this message translates to:
  /// **'Future TCP, Serial, and WebSocket bridge tools.'**
  String get bridgeDescription;

  /// No description provided for @payloadStudioTitle.
  ///
  /// In en, this message translates to:
  /// **'Payload Studio / Converter'**
  String get payloadStudioTitle;

  /// No description provided for @payloadStudioShort.
  ///
  /// In en, this message translates to:
  /// **'Payloads'**
  String get payloadStudioShort;

  /// No description provided for @payloadStudioDescription.
  ///
  /// In en, this message translates to:
  /// **'JSON, text, binary, and checksum conversion workspace.'**
  String get payloadStudioDescription;

  /// No description provided for @apiLabTitle.
  ///
  /// In en, this message translates to:
  /// **'API Lab'**
  String get apiLabTitle;

  /// No description provided for @apiLabShort.
  ///
  /// In en, this message translates to:
  /// **'API'**
  String get apiLabShort;

  /// No description provided for @apiLabDescription.
  ///
  /// In en, this message translates to:
  /// **'HTTP/API testing workspace with collections, environments, variables, and import/export.'**
  String get apiLabDescription;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @restart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restart;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @disable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get disable;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @console.
  ///
  /// In en, this message translates to:
  /// **'Console'**
  String get console;

  /// No description provided for @terminal.
  ///
  /// In en, this message translates to:
  /// **'Terminal'**
  String get terminal;
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
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
