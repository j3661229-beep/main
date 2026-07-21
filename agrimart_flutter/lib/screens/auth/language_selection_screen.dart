import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/indian_languages.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/providers/auth_provider.dart';
import 'package:agrimart/l10n/app_localizations.dart';
import '../../core/utils/responsive.dart';

class LanguageSelectionScreen extends ConsumerWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.r;
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: r.rh(60)),
              // Header
              Text(
                '🌐',
                style: TextStyle(fontSize: r.sp(60)),
              ),
              SizedBox(height: r.rh(24)),
              Text(
                l10n.selectLanguage,
                style: GoogleFonts.spaceGrotesk(fontSize: r.sp(28), fontWeight: FontWeight.w800, color: Colors.white),
              ),
              SizedBox(height: r.rh(12)),
              Text(
                l10n.chooseLanguage,
                style: GoogleFonts.inter(fontSize: r.sp(16), color: Colors.white.withValues(alpha: 0.75)),
              ),
              const Spacer(),
              // Language Cards
              Padding(
                padding: EdgeInsets.symmetric(horizontal: r.rs(24)),
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
                padding: EdgeInsets.all(r.rs(24)),
                child: SizedBox(
                  width: double.infinity,
                  height: r.rh(60),
                  child: ElevatedButton(
                    onPressed: () async {
                      final selected = ref.read(localeProvider);
                      await ref.read(localeProvider.notifier).chooseLanguage(selected);
                      if (!context.mounted) return;
                      final user = ref.read(authProvider).user;
                      if (user != null) {
                        context.go('/farmer');
                      } else {
                        context.go('/auth/login');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.rs(20))),
                      elevation: 0,
                    ),
                    child: Text(
                      l10n.continueBtn,
                      style: GoogleFonts.spaceGrotesk(fontSize: r.sp(18), fontWeight: FontWeight.w700),
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
    final r = context.r;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.all(r.rs(20)),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(r.rs(24)),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.2),
            width: r.rs(2),
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: TextStyle(fontSize: r.sp(32))),
            SizedBox(width: r.rs(20)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: r.sp(18),
                    fontWeight: FontWeight.w700,
                    color: isSelected ? AppColors.farmerAccent : Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: r.sp(14),
                    color: isSelected ? AppColors.farmerAccent.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: AppColors.primary, size: r.sp(28)),
          ],
        ),
      ),
    );
  }
}


