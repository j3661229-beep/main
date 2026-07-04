import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/indian_languages.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/providers/auth_provider.dart';
import 'package:agrimart/l10n/app_localizations.dart';

class LanguageSelectionScreen extends ConsumerWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 60),
              // Header
              const Text(
                '🌐',
                style: TextStyle(fontSize: 60),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.selectLanguage,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.chooseLanguage,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              // Language Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: IndianLanguages.all.map((lang) {
                    final isLast = lang == IndianLanguages.all.last;
                    return Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                      child: _LanguageCard(
                        title: lang.code == 'en'
                            ? l10n.english
                            : lang.code == 'hi'
                                ? l10n.hindi
                                : l10n.marathi,
                        subtitle: lang.nativeName,
                        icon: lang.code == 'en' ? '🇬🇧' : '🇮🇳',
                        isSelected: currentLocale.languageCode == lang.code,
                        onTap: () => ref.read(localeProvider.notifier).setLocale(lang.locale),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Spacer(),
              // Continue Button
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () async {
                      await ref.read(localeProvider.notifier).chooseLanguage(currentLocale);
                      if (!context.mounted) return;
                      final user = ref.read(authProvider).user;
                      if (user != null) {
                        if (user.isFarmer) context.go('/farmer');
                        else if (user.isDealer) context.go('/dealer');
                        else context.go('/supplier');
                      } else {
                        context.go('/auth/role');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: Text(
                      l10n.continueBtn,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppColors.primary : Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 28),
          ],
        ),
      ),
    );
  }
}


