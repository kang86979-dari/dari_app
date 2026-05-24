import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fil.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_he.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_id.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_kk.dart';
import 'app_localizations_km.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_mn.dart';
import 'app_localizations_ms.dart';
import 'app_localizations_my.dart';
import 'app_localizations_ne.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_th.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_uz.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'arb/app_localizations.dart';
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
    Locale('ar'),
    Locale('bn'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fil'),
    Locale('fr'),
    Locale('he'),
    Locale('hi'),
    Locale('id'),
    Locale('it'),
    Locale('ja'),
    Locale('kk'),
    Locale('km'),
    Locale('ko'),
    Locale('mn'),
    Locale('ms'),
    Locale('my'),
    Locale('ne'),
    Locale('pl'),
    Locale('pt'),
    Locale('ru'),
    Locale('th'),
    Locale('tr'),
    Locale('uz'),
    Locale('vi'),
    Locale('zh'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Dari'**
  String get appName;

  /// No description provided for @splashSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Jobs for foreigners'**
  String get splashSubtitle;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select language'**
  String get selectLanguage;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @locationTitle.
  ///
  /// In en, this message translates to:
  /// **'Finding jobs near you'**
  String get locationTitle;

  /// No description provided for @locationDesc.
  ///
  /// In en, this message translates to:
  /// **'Allow location to\nshow nearby jobs first'**
  String get locationDesc;

  /// No description provided for @allowLocation.
  ///
  /// In en, this message translates to:
  /// **'Allow location'**
  String get allowLocation;

  /// No description provided for @denyLocation.
  ///
  /// In en, this message translates to:
  /// **'Don\'t allow'**
  String get denyLocation;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search job, region, company'**
  String get searchHint;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @sortLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get sortLatest;

  /// No description provided for @sortAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Relevance'**
  String get sortAccuracy;

  /// No description provided for @sortSalaryHigh.
  ///
  /// In en, this message translates to:
  /// **'Highest salary'**
  String get sortSalaryHigh;

  /// No description provided for @noJobs.
  ///
  /// In en, this message translates to:
  /// **'No jobs found'**
  String get noJobs;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get changeLanguage;

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language changed'**
  String get languageChanged;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter keyword...'**
  String get searchPlaceholder;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noSearchResults;

  /// No description provided for @tryOtherKeyword.
  ///
  /// In en, this message translates to:
  /// **'Try a different\nkeyword'**
  String get tryOtherKeyword;

  /// No description provided for @tabVisa.
  ///
  /// In en, this message translates to:
  /// **'Visa'**
  String get tabVisa;

  /// No description provided for @tabJobType.
  ///
  /// In en, this message translates to:
  /// **'Job type'**
  String get tabJobType;

  /// No description provided for @tabRegion.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get tabRegion;

  /// No description provided for @tabSalary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get tabSalary;

  /// No description provided for @tabEmployType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get tabEmployType;

  /// No description provided for @tabBenefits.
  ///
  /// In en, this message translates to:
  /// **'Benefits'**
  String get tabBenefits;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @showResults.
  ///
  /// In en, this message translates to:
  /// **'Show results'**
  String get showResults;

  /// No description provided for @jobDetail.
  ///
  /// In en, this message translates to:
  /// **'Job detail'**
  String get jobDetail;

  /// No description provided for @jobNotFound.
  ///
  /// In en, this message translates to:
  /// **'Job not found'**
  String get jobNotFound;

  /// No description provided for @infoSalary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get infoSalary;

  /// No description provided for @infoWorkDays.
  ///
  /// In en, this message translates to:
  /// **'Work days'**
  String get infoWorkDays;

  /// No description provided for @infoWorkTime.
  ///
  /// In en, this message translates to:
  /// **'Work hours'**
  String get infoWorkTime;

  /// No description provided for @infoWorkModel.
  ///
  /// In en, this message translates to:
  /// **'Work type'**
  String get infoWorkModel;

  /// No description provided for @infoEmployType.
  ///
  /// In en, this message translates to:
  /// **'Employment'**
  String get infoEmployType;

  /// No description provided for @infoJobType.
  ///
  /// In en, this message translates to:
  /// **'Job type'**
  String get infoJobType;

  /// No description provided for @infoDeadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get infoDeadline;

  /// No description provided for @infoWorkplace.
  ///
  /// In en, this message translates to:
  /// **'Workplace'**
  String get infoWorkplace;

  /// No description provided for @infoSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get infoSource;

  /// No description provided for @detailContent.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailContent;

  /// No description provided for @disclaimer.
  ///
  /// In en, this message translates to:
  /// **'This information is collected from external sites.\nPlease contact the original site for inquiries.'**
  String get disclaimer;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @alwaysOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get alwaysOpen;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'bn',
    'de',
    'en',
    'es',
    'fil',
    'fr',
    'he',
    'hi',
    'id',
    'it',
    'ja',
    'kk',
    'km',
    'ko',
    'mn',
    'ms',
    'my',
    'ne',
    'pl',
    'pt',
    'ru',
    'th',
    'tr',
    'uz',
    'vi',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'bn':
      return AppLocalizationsBn();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fil':
      return AppLocalizationsFil();
    case 'fr':
      return AppLocalizationsFr();
    case 'he':
      return AppLocalizationsHe();
    case 'hi':
      return AppLocalizationsHi();
    case 'id':
      return AppLocalizationsId();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'kk':
      return AppLocalizationsKk();
    case 'km':
      return AppLocalizationsKm();
    case 'ko':
      return AppLocalizationsKo();
    case 'mn':
      return AppLocalizationsMn();
    case 'ms':
      return AppLocalizationsMs();
    case 'my':
      return AppLocalizationsMy();
    case 'ne':
      return AppLocalizationsNe();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'th':
      return AppLocalizationsTh();
    case 'tr':
      return AppLocalizationsTr();
    case 'uz':
      return AppLocalizationsUz();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
