class AppConstants {
  AppConstants._();

  // API
  // Using 172.20.10.2 to allow your physical device to connect to your PC's locally running backend
  // Alternatively, use 10.0.2.2 for Android Emulator or 127.0.0.1 for iOS simulator.
  static const String baseUrl = 'http://10.10.56.253:3000/api';

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

  // Language
  static const Map<String, String> languages = {
    'marathi': 'मराठी',
    'hindi': 'हिंदी',
    'english': 'English',
  };
}
