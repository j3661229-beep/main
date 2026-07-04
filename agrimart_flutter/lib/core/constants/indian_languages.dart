import 'package:flutter/material.dart';

class IndianLanguage {
  final String code;
  final String englishName;
  final String nativeName;

  const IndianLanguage({
    required this.code,
    required this.englishName,
    required this.nativeName,
  });

  Locale get locale => Locale(code);
}

/// Supported app languages: English, Hindi, Marathi.
class IndianLanguages {
  IndianLanguages._();

  static const String chosenKey = 'language_chosen';
  static const String localeKey = 'selected_locale';

  static const List<IndianLanguage> all = [
    IndianLanguage(code: 'en', englishName: 'English', nativeName: 'English'),
    IndianLanguage(code: 'hi', englishName: 'Hindi', nativeName: 'हिन्दी'),
    IndianLanguage(code: 'mr', englishName: 'Marathi', nativeName: 'मराठी'),
  ];

  static const supportedCodes = ['en', 'hi', 'mr'];

  static bool isSupported(String code) => supportedCodes.contains(code);

  static List<Locale> get locales => all.map((l) => l.locale).toList();
}
