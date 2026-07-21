import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/agri_ui.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../core/utils/responsive.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static const _typeEmoji = {
    'ORDER': '📦',
    'WEATHER': '☀️',
    'PRICE_ALERT': '📈',
    'SCHEME': '🏛️',
    'ADVISORY': '🌾',
    'GENERAL': '📢',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.r;
    final notifications = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: r.rs(120),
            pinned: true,
            backgroundColor: AppColors.farmerAccent,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: Colors.white, size: r.rs(24)),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.farmerGradient),
                padding: EdgeInsets.fromLTRB(r.horizontalPadding, r.safePadding.top + r.rs(48), r.horizontalPadding, r.rs(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('🔔', style: TextStyle(fontSize: r.sp(28))),
                    SizedBox(height: r.rs(6)),
                    Text(
                      'Notifications',
                      style: GoogleFonts.spaceGrotesk(fontSize: r.sp(24), fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: notifications.when(
              loading: () => Padding(
                padding: EdgeInsets.all(r.horizontalPadding),
                child: Column(children: List.generate(4, (_) => Padding(
                  padding: EdgeInsets.only(bottom: r.rs(12)),
                  child: ShimmerBox(height: r.rs(90), radius: 18),
                ))),
              ),
              error: (e, _) => EmptyState(
                emoji: '⚠️',
                title: 'Could not load',
                subtitle: e.toString(),
                actionLabel: 'Retry',
                onAction: () => ref.invalidate(notificationsProvider),
              ),
              data: (data) {
                final list = data['data'] as List? ?? [];
                if (list.isEmpty) {
                  return EmptyState(
                    emoji: '🔔',
                    title: 'No notifications yet',
                    subtitle: 'You\'ll be notified about orders, prices & weather alerts',
                  );
                }
                return Padding(
                  padding: EdgeInsets.fromLTRB(r.horizontalPadding, r.rs(16), r.horizontalPadding, r.rs(32)),
                  child: Column(
                    children: list.map<Widget>((n) {
                      final map = n as Map;
                      final type = map['type'] as String? ?? 'GENERAL';
                      return Padding(
                        padding: EdgeInsets.only(bottom: r.rs(10)),
                        child: FarmerNotificationTile(
                          emoji: _typeEmoji[type] ?? '📢',
                          title: map['title']?.toString() ?? '',
                          body: map['body']?.toString() ?? '',
                          date: map['createdAt']?.toString().split('T').first ?? '',
                          isRead: map['isRead'] as bool? ?? false,
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
