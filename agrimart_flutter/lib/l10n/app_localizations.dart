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

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Trusted partner for farmers'**
  String get tagline;

  /// No description provided for @selectYourRole.
  ///
  /// In en, this message translates to:
  /// **'Select your role'**
  String get selectYourRole;

  /// No description provided for @indianAgriMarketplace.
  ///
  /// In en, this message translates to:
  /// **'Indian Agri-Tech Marketplace'**
  String get indianAgriMarketplace;

  /// No description provided for @farmerRole.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get farmerRole;

  /// No description provided for @supplierRole.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get supplierRole;

  /// No description provided for @dealerRole.
  ///
  /// In en, this message translates to:
  /// **'Dealer'**
  String get dealerRole;

  /// No description provided for @farmerRoleDesc.
  ///
  /// In en, this message translates to:
  /// **'Buy inputs, sell produce & get AI crop advice'**
  String get farmerRoleDesc;

  /// No description provided for @supplierRoleDesc.
  ///
  /// In en, this message translates to:
  /// **'Sell seeds, fertilizers & agricultural products'**
  String get supplierRoleDesc;

  /// No description provided for @dealerRoleDesc.
  ///
  /// In en, this message translates to:
  /// **'Buy produce from farmers & manage mandi deals'**
  String get dealerRoleDesc;

  /// No description provided for @namaste.
  ///
  /// In en, this message translates to:
  /// **'Namaste'**
  String get namaste;

  /// No description provided for @signInAs.
  ///
  /// In en, this message translates to:
  /// **'Sign in as {role}'**
  String signInAs(String role);

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @mandiNewsSection.
  ///
  /// In en, this message translates to:
  /// **'Mandi News'**
  String get mandiNewsSection;

  /// No description provided for @localUpdates.
  ///
  /// In en, this message translates to:
  /// **'Local updates'**
  String get localUpdates;

  /// No description provided for @scanCrop.
  ///
  /// In en, this message translates to:
  /// **'Scan a Crop'**
  String get scanCrop;

  /// No description provided for @aiDiagnosis.
  ///
  /// In en, this message translates to:
  /// **'AI Diagnosis'**
  String get aiDiagnosis;

  /// No description provided for @buyInputs.
  ///
  /// In en, this message translates to:
  /// **'Buy Inputs'**
  String get buyInputs;

  /// No description provided for @seedsAndMore.
  ///
  /// In en, this message translates to:
  /// **'Seeds & More'**
  String get seedsAndMore;

  /// No description provided for @sellProduceAction.
  ///
  /// In en, this message translates to:
  /// **'Sell Produce'**
  String get sellProduceAction;

  /// No description provided for @listYourCrop.
  ///
  /// In en, this message translates to:
  /// **'List your crop'**
  String get listYourCrop;

  /// No description provided for @recentOrders.
  ///
  /// In en, this message translates to:
  /// **'Recent Orders'**
  String get recentOrders;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @noOrdersYet.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get noOrdersYet;

  /// No description provided for @startShoppingInputs.
  ///
  /// In en, this message translates to:
  /// **'Start shopping for farm inputs'**
  String get startShoppingInputs;

  /// No description provided for @browseMarket.
  ///
  /// In en, this message translates to:
  /// **'Browse Market'**
  String get browseMarket;

  /// No description provided for @couldNotLoadOrders.
  ///
  /// In en, this message translates to:
  /// **'Could not load orders'**
  String get couldNotLoadOrders;

  /// No description provided for @nearLocation.
  ///
  /// In en, this message translates to:
  /// **'Near {location}'**
  String nearLocation(String location);

  /// No description provided for @noLocalNewsYet.
  ///
  /// In en, this message translates to:
  /// **'No local news yet'**
  String get noLocalNewsYet;

  /// No description provided for @tapBrowseNews.
  ///
  /// In en, this message translates to:
  /// **'Tap to browse all market updates'**
  String get tapBrowseNews;

  /// No description provided for @diagnose.
  ///
  /// In en, this message translates to:
  /// **'Diagnose'**
  String get diagnose;

  /// No description provided for @market.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get market;

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get mobileNumber;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// No description provided for @emailOrPhone.
  ///
  /// In en, this message translates to:
  /// **'Email or Phone'**
  String get emailOrPhone;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @enterMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile number'**
  String get enterMobileNumber;

  /// No description provided for @validTenDigit.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 10-digit number'**
  String get validTenDigit;

  /// No description provided for @enterEmailOrPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter email or phone'**
  String get enterEmailOrPhone;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orDivider;

  /// No description provided for @bengali.
  ///
  /// In en, this message translates to:
  /// **'Bengali'**
  String get bengali;

  /// No description provided for @telugu.
  ///
  /// In en, this message translates to:
  /// **'Telugu'**
  String get telugu;

  /// No description provided for @tamil.
  ///
  /// In en, this message translates to:
  /// **'Tamil'**
  String get tamil;

  /// No description provided for @gujarati.
  ///
  /// In en, this message translates to:
  /// **'Gujarati'**
  String get gujarati;

  /// No description provided for @kannada.
  ///
  /// In en, this message translates to:
  /// **'Kannada'**
  String get kannada;

  /// No description provided for @malayalam.
  ///
  /// In en, this message translates to:
  /// **'Malayalam'**
  String get malayalam;

  /// No description provided for @punjabi.
  ///
  /// In en, this message translates to:
  /// **'Punjabi'**
  String get punjabi;

  /// No description provided for @odia.
  ///
  /// In en, this message translates to:
  /// **'Odia'**
  String get odia;

  /// No description provided for @assamese.
  ///
  /// In en, this message translates to:
  /// **'Assamese'**
  String get assamese;

  /// No description provided for @urdu.
  ///
  /// In en, this message translates to:
  /// **'Urdu'**
  String get urdu;

  /// No description provided for @selectLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language for the app'**
  String get selectLanguageSubtitle;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @couldNotLoadNews.
  ///
  /// In en, this message translates to:
  /// **'Could not load news'**
  String get couldNotLoadNews;

  /// No description provided for @noNewsRightNow.
  ///
  /// In en, this message translates to:
  /// **'No news right now'**
  String get noNewsRightNow;

  /// No description provided for @newsNotifyLater.
  ///
  /// In en, this message translates to:
  /// **'We will notify you when there are market updates in your area.'**
  String get newsNotifyLater;

  /// No description provided for @localNews.
  ///
  /// In en, this message translates to:
  /// **'Local News'**
  String get localNews;

  /// No description provided for @readFullStory.
  ///
  /// In en, this message translates to:
  /// **'Read full story'**
  String get readFullStory;

  /// No description provided for @readMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get readMore;

  /// No description provided for @weatherUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Weather unavailable'**
  String get weatherUnavailable;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get logIn;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @tools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get tools;

  /// No description provided for @farmToolkit.
  ///
  /// In en, this message translates to:
  /// **'Farm Toolkit'**
  String get farmToolkit;

  /// No description provided for @farmToolkitSubtitle.
  ///
  /// In en, this message translates to:
  /// **'11 tools for your farm'**
  String get farmToolkitSubtitle;

  /// No description provided for @farmToolkitBanner.
  ///
  /// In en, this message translates to:
  /// **'Tap any tool — AI crop doctor, govt schemes, insurance & equipment rental.'**
  String get farmToolkitBanner;

  /// No description provided for @popularTools.
  ///
  /// In en, this message translates to:
  /// **'Popular Tools'**
  String get popularTools;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @todaysAdvisory.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Advisory'**
  String get todaysAdvisory;

  /// No description provided for @viewAdvisory.
  ///
  /// In en, this message translates to:
  /// **'View advisory'**
  String get viewAdvisory;

  /// No description provided for @liveMandiRates.
  ///
  /// In en, this message translates to:
  /// **'Live Mandi Rates'**
  String get liveMandiRates;

  /// No description provided for @perQuintalShort2.
  ///
  /// In en, this message translates to:
  /// **'/qtl'**
  String get perQuintalShort2;

  /// No description provided for @cropDoctor.
  ///
  /// In en, this message translates to:
  /// **'Crop Doctor'**
  String get cropDoctor;

  /// No description provided for @cropDoctorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'AI disease detection'**
  String get cropDoctorSubtitle;

  /// No description provided for @takeCropPhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of your crop'**
  String get takeCropPhoto;

  /// No description provided for @aiIdentifyDisease.
  ///
  /// In en, this message translates to:
  /// **'AI will identify disease & suggest treatment'**
  String get aiIdentifyDisease;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @analyzeCrop.
  ///
  /// In en, this message translates to:
  /// **'Analyze Crop'**
  String get analyzeCrop;

  /// No description provided for @analyzingCrop.
  ///
  /// In en, this message translates to:
  /// **'Analyzing crop...'**
  String get analyzingCrop;

  /// No description provided for @aiWorking.
  ///
  /// In en, this message translates to:
  /// **'AI is analyzing your crop'**
  String get aiWorking;

  /// No description provided for @analysisResult.
  ///
  /// In en, this message translates to:
  /// **'Analysis Result'**
  String get analysisResult;

  /// No description provided for @detectedIssue.
  ///
  /// In en, this message translates to:
  /// **'Detected Issue'**
  String get detectedIssue;

  /// No description provided for @confidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get confidence;

  /// No description provided for @scanHistory.
  ///
  /// In en, this message translates to:
  /// **'Scan History'**
  String get scanHistory;

  /// No description provided for @noScansYet.
  ///
  /// In en, this message translates to:
  /// **'No scans yet'**
  String get noScansYet;

  /// No description provided for @scanHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan a crop to see history here'**
  String get scanHistorySubtitle;

  /// No description provided for @browseProducts.
  ///
  /// In en, this message translates to:
  /// **'Browse market'**
  String get browseProducts;

  /// No description provided for @sellTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Sell to verified dealers'**
  String get sellTabTitle;

  /// No description provided for @sellTabSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Compare live buying rates, book a delivery slot, and track bookings.'**
  String get sellTabSubtitle;

  /// No description provided for @compareDealerRates.
  ///
  /// In en, this message translates to:
  /// **'Compare Dealer Rates'**
  String get compareDealerRates;

  /// No description provided for @myTradeBookings.
  ///
  /// In en, this message translates to:
  /// **'My Trade Bookings'**
  String get myTradeBookings;

  /// No description provided for @bestRateToday.
  ///
  /// In en, this message translates to:
  /// **'Best rate today in {district}'**
  String bestRateToday(String district);

  /// No description provided for @bookSlot.
  ///
  /// In en, this message translates to:
  /// **'Book slot'**
  String get bookSlot;

  /// No description provided for @editFarmProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit farm profile'**
  String get editFarmProfile;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @villageLabel.
  ///
  /// In en, this message translates to:
  /// **'Village'**
  String get villageLabel;

  /// No description provided for @districtLabel.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get districtLabel;

  /// No description provided for @landSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Land size (acres)'**
  String get landSizeLabel;

  /// No description provided for @cropsLabel.
  ///
  /// In en, this message translates to:
  /// **'Crops (comma separated)'**
  String get cropsLabel;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @logOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logOutConfirmTitle;

  /// No description provided for @logOutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'You will be logged out of AgriMart.'**
  String get logOutConfirmMessage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @searchTools.
  ///
  /// In en, this message translates to:
  /// **'Search tools...'**
  String get searchTools;

  /// No description provided for @favoriteTools.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favoriteTools;

  /// No description provided for @recentTools.
  ///
  /// In en, this message translates to:
  /// **'Recently used'**
  String get recentTools;

  /// No description provided for @noToolsMatch.
  ///
  /// In en, this message translates to:
  /// **'No tools match your search'**
  String get noToolsMatch;

  /// No description provided for @offlineTitle.
  ///
  /// In en, this message translates to:
  /// **'You are offline'**
  String get offlineTitle;

  /// No description provided for @offlineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Some features need internet. Cached data may be shown.'**
  String get offlineSubtitle;

  /// No description provided for @kisanPromptSpray.
  ///
  /// In en, this message translates to:
  /// **'When should I spray onion?'**
  String get kisanPromptSpray;

  /// No description provided for @kisanPromptPmfby.
  ///
  /// In en, this message translates to:
  /// **'PMFBY insurance for tomato?'**
  String get kisanPromptPmfby;

  /// No description provided for @kisanPromptMandi.
  ///
  /// In en, this message translates to:
  /// **'Best mandi rate for grapes?'**
  String get kisanPromptMandi;

  /// No description provided for @orderStepPlaced.
  ///
  /// In en, this message translates to:
  /// **'Order placed'**
  String get orderStepPlaced;

  /// No description provided for @orderStepConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get orderStepConfirmed;

  /// No description provided for @orderStepShipped.
  ///
  /// In en, this message translates to:
  /// **'Shipped'**
  String get orderStepShipped;

  /// No description provided for @orderStepDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get orderStepDelivered;

  /// No description provided for @proceedToPay.
  ///
  /// In en, this message translates to:
  /// **'Proceed to Pay'**
  String get proceedToPay;

  /// No description provided for @cartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Cart is empty'**
  String get cartEmpty;

  /// No description provided for @cartEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add items from the market to continue'**
  String get cartEmptySubtitle;

  /// No description provided for @myCart.
  ///
  /// In en, this message translates to:
  /// **'My Cart'**
  String get myCart;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @delivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get delivery;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'FREE'**
  String get free;

  /// No description provided for @addedToCart.
  ///
  /// In en, this message translates to:
  /// **'Added to cart'**
  String get addedToCart;

  /// No description provided for @categoryMarketIntel.
  ///
  /// In en, this message translates to:
  /// **'Market Intel'**
  String get categoryMarketIntel;

  /// No description provided for @categoryAiAdvisory.
  ///
  /// In en, this message translates to:
  /// **'AI & Advisory'**
  String get categoryAiAdvisory;

  /// No description provided for @categorySchemesFinance.
  ///
  /// In en, this message translates to:
  /// **'Schemes & Finance'**
  String get categorySchemesFinance;

  /// No description provided for @categoryTradeRent.
  ///
  /// In en, this message translates to:
  /// **'Trade & Rent'**
  String get categoryTradeRent;

  /// No description provided for @toolsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} TOOLS'**
  String toolsCount(int count);

  /// No description provided for @farmToolkitCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Prices, AI, schemes, insurance & more'**
  String get farmToolkitCardSubtitle;

  /// No description provided for @pullToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Pull down to refresh'**
  String get pullToRefresh;

  /// No description provided for @analysisFailed.
  ///
  /// In en, this message translates to:
  /// **'Analysis failed. Please try again.'**
  String get analysisFailed;

  /// No description provided for @cropLabel.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get cropLabel;

  /// No description provided for @localBadge.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get localBadge;

  /// No description provided for @priceAlerts.
  ///
  /// In en, this message translates to:
  /// **'Price Alerts'**
  String get priceAlerts;

  /// No description provided for @aiPowered.
  ///
  /// In en, this message translates to:
  /// **'AI Powered'**
  String get aiPowered;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get changeLanguage;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @buyInputsTab.
  ///
  /// In en, this message translates to:
  /// **'Buy Inputs'**
  String get buyInputsTab;

  /// No description provided for @sellProduceTab.
  ///
  /// In en, this message translates to:
  /// **'Sell Produce'**
  String get sellProduceTab;

  /// No description provided for @noRatesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No rates available'**
  String get noRatesAvailable;

  /// No description provided for @tapForPriceAlerts.
  ///
  /// In en, this message translates to:
  /// **'Set price alerts'**
  String get tapForPriceAlerts;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @currentStep.
  ///
  /// In en, this message translates to:
  /// **'CURRENT'**
  String get currentStep;

  /// No description provided for @treatmentRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Treatment Recommendation'**
  String get treatmentRecommendation;

  /// No description provided for @noAdvisoryToday.
  ///
  /// In en, this message translates to:
  /// **'No advisory available today.'**
  String get noAdvisoryToday;

  /// No description provided for @acresUnit.
  ///
  /// In en, this message translates to:
  /// **'acres'**
  String get acresUnit;
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
