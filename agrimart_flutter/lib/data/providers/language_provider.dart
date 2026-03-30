import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _storage = FlutterSecureStorage();
const _langKey = 'app_language';

class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super('English') {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final lang = await _storage.read(key: _langKey);
    if (lang != null) {
      state = lang;
    }
  }

  Future<void> setLanguage(String lang) async {
    await _storage.write(key: _langKey, value: lang);
    state = lang;
  }
}

import './language_provider.dart';
import '../core/i18n/app_translations.dart';

extension LanguageHelper on WidgetRef {
  String tr(String key) {
    final lang = watch(languageProvider);
    return AppTranslations.translate(key, lang);
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier();
});

