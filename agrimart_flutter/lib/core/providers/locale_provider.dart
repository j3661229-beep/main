import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/indian_languages.dart';

/// Whether the user completed first-launch language selection.
final languageChosenProvider = StateNotifierProvider<LanguageChosenNotifier, bool>((ref) {
  return LanguageChosenNotifier();
});

class LanguageChosenNotifier extends StateNotifier<bool> {
  LanguageChosenNotifier({bool? initial}) : super(initial ?? false) {
    if (initial == null) _load();
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
  LocaleNotifier(this._ref, {Locale? initialLocale}) : super(initialLocale ?? const Locale('en')) {
    if (initialLocale == null) _loadLocale();
  }

  final Ref _ref;

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(IndianLanguages.localeKey) ?? 'en';
    if (IndianLanguages.isSupported(languageCode)) {
      state = Locale(languageCode);
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (!IndianLanguages.isSupported(locale.languageCode)) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(IndianLanguages.localeKey, locale.languageCode);
    state = locale;
  }

  /// Save language and mark first-launch flow complete.
  Future<void> chooseLanguage(Locale locale) async {
    await setLocale(locale);
    await _ref.read(languageChosenProvider.notifier).markChosen();
  }

  /// Map backend language strings (e.g. marathi) to app locale codes.
  static Locale? localeFromUserLanguage(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final v = raw.toLowerCase();
    if (v.startsWith('mr') || v.contains('marathi') || v.contains('मराठी')) return const Locale('mr');
    if (v.startsWith('hi') || v.contains('hindi') || v.contains('हिन')) return const Locale('hi');
    if (v.startsWith('en') || v.contains('english')) return const Locale('en');
    return null;
  }
}

/// Load saved locale + language-chosen flag before first frame.
Future<({Locale locale, bool languageChosen})> loadLocaleBootstrap() async {
  final prefs = await SharedPreferences.getInstance();
  final languageCode = prefs.getString(IndianLanguages.localeKey) ?? 'en';
  final locale = IndianLanguages.isSupported(languageCode) ? Locale(languageCode) : const Locale('en');
  final languageChosen = prefs.getBool(IndianLanguages.chosenKey) ?? false;
  return (locale: locale, languageChosen: languageChosen);
}
