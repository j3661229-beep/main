import 'package:flutter/foundation.dart';

class AppConstants {
  AppConstants._();

  // Production — Google Cloud Run (europe-west1)
  static const String productionApiUrl =
      'https://agrimart-775670922011.europe-west1.run.app/api';

  // Local backend (same Wi‑Fi as phone/emulator)
  static const String localApiUrl = 'http://192.168.216.185:3000/api';

  // Override at build time: flutter run --dart-define=API_BASE_URL=...
  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    return kDebugMode ? localApiUrl : productionApiUrl;
  }

  /// Normalized base URL — always ends with `/api`.
  static String get apiBaseUrl {
    var url = baseUrl.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (!url.endsWith('/api')) {
      url = '$url/api';
    }
    return url;
  }

  // YouTube Data API v3 (Krishi TV) — restrict key in Google Cloud Console to Android app + YouTube Data API v3 only
  static const String youtubeApiKey = String.fromEnvironment(
    'YOUTUBE_API_KEY',
    defaultValue: 'AIzaSyAqyDXY0owpfN_VrMbv-XCNt9ziBnYG10A',
  );

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String languageKey = 'app_language';
  static const String onboardingKey = 'onboarding_done';

  // Timeouts
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 30000;

  // Pagination
  static const int defaultPageSize = 20;

  // Platform commission
  static const double commissionRate = 0.025;
  static const double freeDeliveryAbove = 500;

  // Categories
  static const List<Map<String, String>> categories = [
    {'key': 'SEEDS', 'label': 'Seeds', 'labelMr': 'बियाणे', 'icon': '🌱'},
    {'key': 'FERTILIZER', 'label': 'Fertilizer', 'labelMr': 'खत', 'icon': '🧪'},
    {'key': 'PESTICIDE', 'label': 'Pesticide', 'labelMr': 'कीटकनाशक', 'icon': '🛡️'},
    {'key': 'ORGANIC', 'label': 'Organic', 'labelMr': 'सेंद्रिय', 'icon': '🌿'},
    {'key': 'EQUIPMENT', 'label': 'Equipment', 'labelMr': 'साधने', 'icon': '🔧'},
    {'key': 'OTHER', 'label': 'Other', 'labelMr': 'इतर', 'icon': '📦'},
  ];

  // Maharashtra districts
  static const List<String> maharashtraDistricts = [
    'Nashik', 'Pune', 'Aurangabad', 'Nagpur', 'Kolhapur',
    'Solapur', 'Sangli', 'Satara', 'Ahmednagar', 'Nanded',
    'Latur', 'Osmanabad', 'Jalna', 'Beed', 'Parbhani',
    'Hingoli', 'Buldhana', 'Akola', 'Washim', 'Amravati',
    'Wardha', 'Yavatmal', 'Chandrapur', 'Gadchiroli', 'Gondia',
    'Bhandara', 'Dhule', 'Nandurbar', 'Jalgaon', 'Ratnagiri',
    'Sindhudurg', 'Raigad', 'Thane', 'Mumbai Suburban', 'Mumbai City',
    'Palghar',
  ];

  // Crops
  static const List<Map<String, String>> popularCrops = [
    {'name': 'Onion', 'emoji': '🧅', 'nameMr': 'कांदा'},
    {'name': 'Tomato', 'emoji': '🍅', 'nameMr': 'टोमॅटो'},
    {'name': 'Wheat', 'emoji': '🌾', 'nameMr': 'गहू'},
    {'name': 'Soybean', 'emoji': '🫘', 'nameMr': 'सोयाबीन'},
    {'name': 'Cotton', 'emoji': '🌿', 'nameMr': 'कापूस'},
    {'name': 'Grapes', 'emoji': '🍇', 'nameMr': 'द्राक्षे'},
    {'name': 'Sugarcane', 'emoji': '🍬', 'nameMr': 'ऊस'},
    {'name': 'Maize', 'emoji': '🌽', 'nameMr': 'मका'},
  ];

  // Language (both API format and legacy keys)
  static const Map<String, String> languages = {
    'en':      'English',
    'hi':      'हिंदी',
    'mr':      'मराठी',
    'english': 'English',
    'hindi':   'हिंदी',
    'marathi': 'मराठी',
  };

  // Placeholder image asset
  static const String placeholderImage = 'assets/images/placeholder.png';
}


