import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_language.dart';
import 'locale_provider.dart';

/// Current app language derived from [localeProvider] — use for all AI API calls.
final appLanguageProvider = Provider<AppLanguage>((ref) {
  return AppLanguage.fromLocale(ref.watch(localeProvider));
});
