import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agrimart/l10n/app_localizations.dart';
import '../constants/indian_languages.dart';
import '../providers/locale_provider.dart';
import '../theme/app_colors.dart';
import '../utils/responsive.dart';

/// Opens language picker tied to the same Riverpod container as the caller.
Future<void> showLanguagePickerSheet(BuildContext context, WidgetRef ref) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final messenger = ScaffoldMessenger.maybeOf(context);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return UncontrolledProviderScope(
        container: container,
        child: _LanguagePickerSheet(
          onChanged: (locale) async {
            await ref.read(localeProvider.notifier).setLocale(locale, syncBackend: true);
            if (sheetContext.mounted) Navigator.of(sheetContext).pop();
            messenger?.showSnackBar(
              SnackBar(
                content: Text(
                  locale.languageCode == 'mr'
                      ? 'भाषा मराठी मध्ये बदलली'
                      : locale.languageCode == 'hi'
                          ? 'भाषा हिंदी में बदल गई'
                          : 'Language changed to English',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      );
    },
  );
}

class _LanguagePickerSheet extends ConsumerWidget {
  final Future<void> Function(Locale locale) onChanged;

  const _LanguagePickerSheet({required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final current = ref.watch(localeProvider);
    final r = context.r;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(r.horizontalPadding, r.rs(20), r.horizontalPadding, r.rs(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: r.rs(16)),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              l10n.changeLanguage,
              style: GoogleFonts.spaceGrotesk(fontSize: r.sp(18), fontWeight: FontWeight.w700),
            ),
            SizedBox(height: r.rs(8)),
            Text(
              l10n.selectLanguageSubtitle,
              style: GoogleFonts.inter(fontSize: r.sp(12), color: AppColors.muted),
            ),
            SizedBox(height: r.rs(16)),
            ...IndianLanguages.all.map((lang) {
              final selected = current.languageCode == lang.code;
              final title = lang.code == 'en'
                  ? l10n.english
                  : lang.code == 'hi'
                      ? l10n.hindi
                      : l10n.marathi;

              return Material(
                color: selected ? AppColors.farmerTint : Colors.transparent,
                borderRadius: BorderRadius.circular(r.rs(14)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(r.rs(14)),
                  onTap: selected ? () => Navigator.of(context).pop() : () => onChanged(lang.locale),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: r.rs(8), vertical: r.rs(4)),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Text(lang.code == 'en' ? '🇬🇧' : '🇮🇳', style: TextStyle(fontSize: r.sp(24))),
                      title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      subtitle: Text(lang.nativeName),
                      trailing: selected
                          ? const Icon(Icons.check_circle_rounded, color: AppColors.farmerAccent)
                          : const Icon(Icons.circle_outlined, color: AppColors.muted),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
