import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReviewService {
  static final InAppReview _inAppReview = InAppReview.instance;

  static Future<void> checkAndPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    int deliveries = prefs.getInt('successful_deliveries') ?? 0;
    bool alreadyRated = prefs.getBool('already_rated_v1') ?? false;

    if (alreadyRated) return;

    // Prompt on 3rd successful delivery
    if (deliveries >= 3) {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
        await prefs.setBool('already_rated_v1', true);
      }
    }
  }

  static Future<void> incrementDeliveries() async {
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt('successful_deliveries') ?? 0;
    await prefs.setInt('successful_deliveries', current + 1);
    await checkAndPrompt();
  }
}
