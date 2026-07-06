import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/agri_ui.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../data/providers/app_providers.dart';
import '../../data/providers/auth_provider.dart';
import '../../core/widgets/app_fallback.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/utils/responsive.dart';

class CropCalendarScreen extends ConsumerWidget {
  const CropCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.r;
    final district = ref.watch(authProvider).user?.effectiveDistrict ?? 'Nashik';
    final crops = ref.watch(authProvider).user?.farmer?['currentCrops'];
    final cropStr = crops is List ? crops.join(', ') : 'Onion, Tomato, Soybean';
    final key = '$district|$cropStr';
    final calendar = ref.watch(cropCalendarProvider(key));

    return AgriScreen(
      title: 'Crop Calendar',
      subtitle: 'What to do this month',
      emoji: '📅',
      onRefresh: () async => ref.invalidate(cropCalendarProvider(key)),
      body: calendar.when(
        loading: () => const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: AppErrorState(
            message: extractUserFacingError(e),
            onRetry: () => ref.invalidate(cropCalendarProvider(key)),
          ),
        ),
        data: (data) {
          final activities = (data['activities'] as List?) ?? [];
          if (activities.isEmpty) {
            return const EmptyState(emoji: '📅', title: 'No activities', subtitle: 'Try again later');
          }
          return Padding(
            padding: EdgeInsets.fromLTRB(r.horizontalPadding, 20, r.horizontalPadding, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoBanner(
                  text: '${data['month'] ?? 'This month'} • ${data['district'] ?? district} • $cropStr',
                  icon: Icons.calendar_month_rounded,
                ),
                const SizedBox(height: 20),
                ...activities.map((a) {
                  final item = a as Map;
                  final urgency = (item['urgency'] ?? '').toString().toLowerCase();
                  final color = urgency.contains('high')
                      ? AppColors.danger
                      : urgency.contains('medium')
                          ? AppColors.warning
                          : AppColors.farmerAccent;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AgriCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                            child: Center(child: Text(item['emoji'] ?? '🌱', style: TextStyle(fontSize: r.sp(24)))),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item['crop'] ?? ''} — ${item['action'] ?? ''}',
                                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 15),
                                ),
                                const SizedBox(height: 4),
                                Text(item['description'] ?? '', style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted, height: 1.4)),
                                if (urgency.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  BadgeChip(label: urgency.toUpperCase(), color: color.withValues(alpha: 0.12), textColor: color),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
