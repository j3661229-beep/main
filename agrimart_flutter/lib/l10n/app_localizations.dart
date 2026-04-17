import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';

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
    Locale('hi'),
    Locale('mr')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'AgriMart'**
  String get appName;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get hindi;

  /// No description provided for @marathi.
  ///
  /// In en, this message translates to:
  /// **'Marathi'**
  String get marathi;

  /// No description provided for @continueBtn.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueBtn;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to AgriMart'**
  String get welcome;

  /// No description provided for @loginWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Login with Google'**
  String get loginWithGoogle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @shop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shop;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @kisanAi.
  ///
  /// In en, this message translates to:
  /// **'Kisan AI'**
  String get kisanAi;

  /// No description provided for @mandiPrices.
  ///
  /// In en, this message translates to:
  /// **'Mandi Prices'**
  String get mandiPrices;

  /// No description provided for @sellCrops.
  ///
  /// In en, this message translates to:
  /// **'Sell Crops'**
  String get sellCrops;

  /// No description provided for @govtSchemes.
  ///
  /// In en, this message translates to:
  /// **'Govt Schemes'**
  String get govtSchemes;

  /// No description provided for @soilAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Soil Analysis'**
  String get soilAnalysis;

  /// No description provided for @diseaseDetection.
  ///
  /// In en, this message translates to:
  /// **'Disease Detection'**
  String get diseaseDetection;

  /// No description provided for @cropAdvisor.
  ///
  /// In en, this message translates to:
  /// **'Crop Advisor'**
  String get cropAdvisor;

  /// No description provided for @weather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weather;

  /// No description provided for @aiHub.
  ///
  /// In en, this message translates to:
  /// **'AI Hub'**
  String get aiHub;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @accountManagement.
  ///
  /// In en, this message translates to:
  /// **'Account Management'**
  String get accountManagement;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguage;

  /// No description provided for @supportLegal.
  ///
  /// In en, this message translates to:
  /// **'Support & Legal'**
  String get supportLegal;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About AgriMart'**
  String get aboutUs;

  /// No description provided for @farmDetails.
  ///
  /// In en, this message translates to:
  /// **'Farm Details'**
  String get farmDetails;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @soilType.
  ///
  /// In en, this message translates to:
  /// **'Soil Type'**
  String get soilType;

  /// No description provided for @season.
  ///
  /// In en, this message translates to:
  /// **'Season'**
  String get season;

  /// No description provided for @farmSize.
  ///
  /// In en, this message translates to:
  /// **'Farm Size'**
  String get farmSize;

  /// No description provided for @getAiRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Get AI Recommendations'**
  String get getAiRecommendations;

  /// No description provided for @detectDisease.
  ///
  /// In en, this message translates to:
  /// **'Detect Disease'**
  String get detectDisease;

  /// No description provided for @analyzeSoil.
  ///
  /// In en, this message translates to:
  /// **'Analyze Soil'**
  String get analyzeSoil;

  /// No description provided for @aiAdvisory.
  ///
  /// In en, this message translates to:
  /// **'AI Advisory'**
  String get aiAdvisory;

  /// No description provided for @recommendedCrops.
  ///
  /// In en, this message translates to:
  /// **'Recommended Crops'**
  String get recommendedCrops;

  /// No description provided for @treatmentPlan.
  ///
  /// In en, this message translates to:
  /// **'Treatment Plan'**
  String get treatmentPlan;

  /// No description provided for @humidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get humidity;

  /// No description provided for @wind.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get wind;

  /// No description provided for @feelsLike.
  ///
  /// In en, this message translates to:
  /// **'Feels Like'**
  String get feelsLike;

  /// No description provided for @maxTemp.
  ///
  /// In en, this message translates to:
  /// **'Max Temp'**
  String get maxTemp;

  /// No description provided for @minTemp.
  ///
  /// In en, this message translates to:
  /// **'Min Temp'**
  String get minTemp;

  /// No description provided for @benefits.
  ///
  /// In en, this message translates to:
  /// **'Benefits'**
  String get benefits;

  /// No description provided for @eligibility.
  ///
  /// In en, this message translates to:
  /// **'Eligibility'**
  String get eligibility;

  /// No description provided for @documentsNeeded.
  ///
  /// In en, this message translates to:
  /// **'Documents Needed'**
  String get documentsNeeded;

  /// No description provided for @applyOnline.
  ///
  /// In en, this message translates to:
  /// **'Apply Online'**
  String get applyOnline;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get chooseLanguage;

  /// No description provided for @farmAdvisory.
  ///
  /// In en, this message translates to:
  /// **'Farm Advisory'**
  String get farmAdvisory;

  /// No description provided for @liveMarket.
  ///
  /// In en, this message translates to:
  /// **'Live Market'**
  String get liveMarket;

  /// No description provided for @agmarknetLive.
  ///
  /// In en, this message translates to:
  /// **'AGMARKNET LIVE'**
  String get agmarknetLive;

  /// No description provided for @directBuyers.
  ///
  /// In en, this message translates to:
  /// **'DIRECT BUYERS'**
  String get directBuyers;

  /// No description provided for @marketDataUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Market data currently unavailable'**
  String get marketDataUnavailable;

  /// No description provided for @marketClosed.
  ///
  /// In en, this message translates to:
  /// **'Market Closed'**
  String get marketClosed;

  /// No description provided for @noLiveRates.
  ///
  /// In en, this message translates to:
  /// **'No live rates available for your current region.'**
  String get noLiveRates;

  /// No description provided for @liveAgmarknetFeed.
  ///
  /// In en, this message translates to:
  /// **'Live AGMARKNET Feed'**
  String get liveAgmarknetFeed;

  /// No description provided for @marketOpen.
  ///
  /// In en, this message translates to:
  /// **'MARKET OPEN'**
  String get marketOpen;

  /// No description provided for @topVerifiedDealers.
  ///
  /// In en, this message translates to:
  /// **'Top Verified Dealers'**
  String get topVerifiedDealers;

  /// No description provided for @sellPrefix.
  ///
  /// In en, this message translates to:
  /// **'Sell'**
  String get sellPrefix;

  /// No description provided for @verifiedDealersNearby.
  ///
  /// In en, this message translates to:
  /// **'Verified Buyers nearby'**
  String get verifiedDealersNearby;

  /// No description provided for @perQuintal.
  ///
  /// In en, this message translates to:
  /// **'per quintal'**
  String get perQuintal;

  /// No description provided for @viewDealersBookSlot.
  ///
  /// In en, this message translates to:
  /// **'VIEW DEALERS & BOOK SLOT'**
  String get viewDealersBookSlot;

  /// No description provided for @directTrading.
  ///
  /// In en, this message translates to:
  /// **'Direct Trading'**
  String get directTrading;

  /// No description provided for @directTradingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Skip the mandi queues. Sell directly to verified district dealers at competitive rates.'**
  String get directTradingSubtitle;

  /// No description provided for @exploreByCategory.
  ///
  /// In en, this message translates to:
  /// **'Explore by Category'**
  String get exploreByCategory;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @nearest.
  ///
  /// In en, this message translates to:
  /// **'Nearest'**
  String get nearest;

  /// No description provided for @newest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get newest;

  /// No description provided for @priceAsc.
  ///
  /// In en, this message translates to:
  /// **'Price ↑'**
  String get priceAsc;

  /// No description provided for @priceDesc.
  ///
  /// In en, this message translates to:
  /// **'Price ↓'**
  String get priceDesc;

  /// No description provided for @availableNearYou.
  ///
  /// In en, this message translates to:
  /// **'Available Near You'**
  String get availableNearYou;

  /// No description provided for @noProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get noProductsFound;

  /// No description provided for @clearFiltersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try clearing your search or category filters'**
  String get clearFiltersSubtitle;

  /// No description provided for @itemCount.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get itemCount;

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get itemsCount;

  /// No description provided for @viewCart.
  ///
  /// In en, this message translates to:
  /// **'View Cart'**
  String get viewCart;

  /// No description provided for @organic.
  ///
  /// In en, this message translates to:
  /// **'ORGANIC'**
  String get organic;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'ADD'**
  String get add;

  /// No description provided for @approxWeightQuintals.
  ///
  /// In en, this message translates to:
  /// **'Approximate Weight (Quintals)'**
  String get approxWeightQuintals;

  /// No description provided for @enterWeightError.
  ///
  /// In en, this message translates to:
  /// **'Please enter approximate weight (Quintals)'**
  String get enterWeightError;

  /// No description provided for @bookingConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Booking Confirmed!'**
  String get bookingConfirmed;

  /// No description provided for @deliverySlotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Your physical delivery slot is confirmed for'**
  String get deliverySlotConfirmed;

  /// No description provided for @backToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Back to Dashboard'**
  String get backToDashboard;

  /// No description provided for @errorBookingSlot.
  ///
  /// In en, this message translates to:
  /// **'Error booking slot'**
  String get errorBookingSlot;

  /// No description provided for @selectLocalDealer.
  ///
  /// In en, this message translates to:
  /// **'Select Local Dealer'**
  String get selectLocalDealer;

  /// No description provided for @verifiedDistrict.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verifiedDistrict;

  /// No description provided for @perQuintalShort.
  ///
  /// In en, this message translates to:
  /// **'/ quintal'**
  String get perQuintalShort;

  /// No description provided for @bookingDetails.
  ///
  /// In en, this message translates to:
  /// **'Booking Details'**
  String get bookingDetails;

  /// No description provided for @dropOffDate.
  ///
  /// In en, this message translates to:
  /// **'Drop-off Date'**
  String get dropOffDate;

  /// No description provided for @additionalNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Additional Notes (Optional)'**
  String get additionalNotesOptional;

  /// No description provided for @confirmBookingSlot.
  ///
  /// In en, this message translates to:
  /// **'Confirm Booking Slot'**
  String get confirmBookingSlot;

  /// No description provided for @noDealersFound.
  ///
  /// In en, this message translates to:
  /// **'No dealers found for {crop} in {district}.'**
  String noDealersFound(Object crop, Object district);

  /// No description provided for @spent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get spent;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @farm.
  ///
  /// In en, this message translates to:
  /// **'Farm'**
  String get farm;

  /// No description provided for @servicesAi.
  ///
  /// In en, this message translates to:
  /// **'AI Services'**
  String get servicesAi;

  /// No description provided for @searchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search crops or markets'**
  String get searchProducts;

  /// No description provided for @orderTracking.
  ///
  /// In en, this message translates to:
  /// **'Order Tracking'**
  String get orderTracking;

  /// No description provided for @pickupLocation.
  ///
  /// In en, this message translates to:
  /// **'PICKUP LOCATION'**
  String get pickupLocation;

  /// No description provided for @navigateToStore.
  ///
  /// In en, this message translates to:
  /// **'Navigate to Store'**
  String get navigateToStore;

  /// No description provided for @store.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get store;

  /// No description provided for @trackingHistory.
  ///
  /// In en, this message translates to:
  /// **'Tracking History'**
  String get trackingHistory;

  /// No description provided for @orderItems.
  ///
  /// In en, this message translates to:
  /// **'Order Items'**
  String get orderItems;

  /// No description provided for @pickupProgress.
  ///
  /// In en, this message translates to:
  /// **'Pickup Progress'**
  String get pickupProgress;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'ready'**
  String get ready;

  /// No description provided for @locationNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Store location not available'**
  String get locationNotAvailable;

  /// No description provided for @mapsNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Could not open Maps app'**
  String get mapsNotAvailable;

  /// No description provided for @browsing.
  ///
  /// In en, this message translates to:
  /// **'Browsing'**
  String get browsing;

  /// No description provided for @viewShop.
  ///
  /// In en, this message translates to:
  /// **'View Shop'**
  String get viewShop;

  /// No description provided for @noProductsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No products available'**
  String get noProductsAvailable;
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
      <String>['en', 'hi', 'mr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'mr':
      return AppLocalizationsMr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
