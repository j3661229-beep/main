import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agrimart/l10n/app_localizations.dart';
import '../providers/connectivity_provider.dart';
import '../theme/app_colors.dart';
import '../utils/responsive.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(isOnlineProvider);
    if (online) return const SizedBox.shrink();

    final r = context.r;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: r.rs(12)),
      padding: EdgeInsets.symmetric(horizontal: r.rs(14), vertical: r.rs(12)),
      decoration: BoxDecoration(
        color: AppColors.warningTint,
        borderRadius: BorderRadius.circular(r.rs(14)),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, color: AppColors.warning, size: r.rs(22)),
          SizedBox(width: r.rs(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.offlineTitle, style: GoogleFonts.spaceGrotesk(fontSize: r.sp(14), fontWeight: FontWeight.w700, color: AppColors.warning)),
                Text(l10n.offlineSubtitle, style: GoogleFonts.inter(fontSize: r.sp(12), color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
