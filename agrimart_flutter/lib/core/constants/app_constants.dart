class AppConstants {
  AppConstants._();

  // API — backend mounts at /api (not /api/v1)
  // Override at build time: flutter run --dart-define=API_BASE_URL=http://YOUR_IP:3000/api
  // Physical device on same Wi‑Fi: use PC LAN IP (ipconfig). USB debugging alternative:
  //   adb reverse tcp:3000 tcp:3000  then  --dart-define=API_BASE_URL=http://127.0.0.1:3000/api
  // Android emulator: http://10.0.2.2:3000/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.59.22.186:3000/api',
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


