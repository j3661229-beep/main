import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_fallback.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('🔔 Notifications'), backgroundColor: AppColors.primary, actions: [
        TextButton(onPressed: () {}, child: const Text('Mark All Read', style: TextStyle(color: Colors.white70, fontSize: 13))),
      ]),
      body: notifications.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorState(
          message: e.toString(),
          onRetry: () => ref.refresh(notificationsProvider),
        ),
        data: (data) {
          final list = data['data'] as List? ?? [];
          if (list.isEmpty) {
            return const AppEmptyState(
              icon: '🔔',
              title: 'No notifications yet',
              subtitle: 'You\'ll be notified about orders, prices & weather',
            );
          }

          final typeEmoji = {'ORDER': '📦', 'WEATHER': '☀️', 'PRICE_ALERT': '📈', 'SCHEME': '🏛️', 'ADVISORY': '🌾', 'GENERAL': '📢'};

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: list.length,
            itemBuilder: (ctx, i) {
              final n = list[i] as Map;
              final isRead = n['isRead'] as bool? ?? false;
              final type = n['type'] as String? ?? 'GENERAL';
              return Container(
                decoration: BoxDecoration(color: isRead ? AppColors.surface : AppColors.primarySurface.withOpacity(0.4), border: Border(bottom: BorderSide(color: AppColors.border))),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(12)),
                    child: Center(child: Text(typeEmoji[type] ?? '📢', style: const TextStyle(fontSize: 22)))),
                  title: Text(n['title'] ?? '', style: AppTextStyles.headingSM.copyWith(fontWeight: isRead ? FontWeight.w500 : FontWeight.w700)),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const SizedBox(height: 2),
                    Text(n['body'] ?? '', style: AppTextStyles.bodySM, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(n['createdAt']?.toString().split('T').first ?? '', style: AppTextStyles.caption),
                  ]),
                  trailing: !isRead ? Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)) : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
