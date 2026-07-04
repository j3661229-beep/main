import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/indian_languages.dart';

/// Whether the user completed first-launch language selection.
final languageChosenProvider = StateNotifierProvider<LanguageChosenNotifier, bool>((ref) {
  return LanguageChosenNotifier();
});

class LanguageChosenNotifier extends StateNotifier<bool> {
  LanguageChosenNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(IndianLanguages.chosenKey) ?? false;
  }

  Future<void> markChosen() async {
    state = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(IndianLanguages.chosenKey, true);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier(ref);
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier(this._ref) : super(const Locale('en')) {
    _loadLocale();
  }

  final Ref _ref;

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(IndianLanguages.localeKey) ?? 'en';
    if (IndianLanguages.isSupported(languageCode)) {
      state = Locale(languageCode);
    }
    state = state; // notify after async load
  }

  Future<void> setLocale(Locale locale) async {
    if (!IndianLanguages.isSupported(locale.languageCode)) return;

    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(IndianLanguages.localeKey, locale.languageCode);
  }

  /// Save language and mark first-launch flow complete.
  Future<void> chooseLanguage(Locale locale) async {
    await setLocale(locale);
    await _ref.read(languageChosenProvider.notifier).markChosen();
  }
}
