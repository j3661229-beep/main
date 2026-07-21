import 'package:flutter/material.dart';

/// Central mapping between app locale, backend user.language, and AI API language names.
class AppLanguage {
  final String code;

  const AppLanguage(this.code);

  static const supported = ['en', 'hi', 'mr'];

  factory AppLanguage.fromCode(String? code) {
    final c = (code ?? 'en').toLowerCase();
    if (c == 'hi' || c.startsWith('hi')) return const AppLanguage('hi');
    if (c == 'mr' || c.startsWith('mr')) return const AppLanguage('mr');
    return const AppLanguage('en');
  }

  factory AppLanguage.fromUserString(String? raw) {
    if (raw == null || raw.isEmpty) return const AppLanguage('en');
    final v = raw.toLowerCase();
    if (v == 'mr' || v.contains('marathi') || v.contains('मराठी')) return const AppLanguage('mr');
    if (v == 'hi' || v.contains('hindi') || v.contains('हिन')) return const AppLanguage('hi');
    if (v == 'en' || v.contains('english')) return const AppLanguage('en');
    return AppLanguage.fromCode(raw);
  }

  factory AppLanguage.fromLocale(Locale locale) => AppLanguage.fromCode(locale.languageCode);

  Locale get locale => Locale(code);

  /// Sent to AI endpoints (`language` field).
  String get aiName {
    switch (code) {
      case 'hi':
        return 'Hindi';
      case 'mr':
        return 'Marathi';
      default:
        return 'English';
    }
  }

  /// Google News RSS language (`hl` query param).
  String get newsHl {
    switch (code) {
      case 'hi':
        return 'hi-IN';
      case 'mr':
        return 'mr-IN';
      default:
        return 'en-IN';
    }
  }

  String get newsCeid {
    switch (code) {
      case 'hi':
        return 'IN:hi';
      case 'mr':
        return 'IN:mr';
      default:
        return 'IN:en';
    }
  }

  /// YouTube `relevanceLanguage` parameter.
  String get youtubeLang => code;

  String farmingNewsQuery({required String district, required String state}) {
    switch (code) {
      case 'mr':
        return '$district $state शेती मंडी शेतकरी when:14d';
      case 'hi':
        return '$district $state कृषि मंडी किसान when:14d';
      default:
        return '$district agriculture mandi farmer crop $state India when:14d';
    }
  }

  String secondaryNewsQuery({required String district, required String state}) {
    switch (code) {
      case 'mr':
        return '$district $state शेतकरी बाजार भाव when:14d';
      case 'hi':
        return '$district $state किसान फसल बाजार when:14d';
      default:
        return '$district $state farmer crop market when:14d';
    }
  }

  String youtubeLocationSuffix({required String district, required String state, String? village}) {
    final loc = [village, district, state].where((e) => e != null && e.trim().isNotEmpty).join(' ');
    switch (code) {
      case 'mr':
        return 'शेती $loc';
      case 'hi':
        return 'खेती किसान $loc';
      default:
        return 'farming $loc India';
    }
  }

  String youtubeTrendingQuery({required String district, required String state}) {
    switch (code) {
      case 'mr':
        return 'शेती सल्ला $district $state 2024';
      case 'hi':
        return 'खेती सुझाव $district $state 2024';
      default:
        return 'farming tips $district $state 2024';
    }
  }

  /// Stored on User.language in backend.
  String get backendCode => code;
}
