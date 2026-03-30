// Quick stub screens for remaining routes
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_fallback.dart';
import '../../core/widgets/app_shimmer.dart';

class OrderTrackingScreen extends ConsumerWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracking = ref.watch(orderTrackingProvider(orderId));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
          title: const Text('📍 Order Tracking', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          backgroundColor: AppColors.primary,
          elevation: 0,
          centerTitle: true),
      body: tracking.when(
        loading: () => const AppShimmerList(),
        error: (e, _) => AppErrorState(
            message: 'Could not load tracking details',
            onRetry: () => ref.invalidate(orderTrackingProvider)),
        data: (data) {
          final backendSteps = (data['tracking'] as List? ?? []);
          final order = data['order'] as Map? ?? {};
          final items = order['items'] as List? ?? [];
          final supplier = items.isNotEmpty ? items.first['supplier'] : null;
          final storeName = supplier != null ? supplier['businessName'] : 'Store';
          final storeAddress = supplier != null ? supplier['address'] : 'Address unavailable';
          final parsedAddress = storeAddress.split(' | MAP: ');
          final cleanAddress = parsedAddress[0];
          final mapLink = parsedAddress.length > 1 ? parsedAddress[1] : null;

          return ListView(padding: const EdgeInsets.all(24), children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(children: [
                     const Icon(Icons.storefront, color: AppColors.primaryDark),
                     const SizedBox(width: 8),
                     const Text('Pickup Location', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                   ]),
                   const SizedBox(height: 12),
                   Text(storeName, style: AppTextStyles.headingLG),
                   const SizedBox(height: 4),
                   SelectableText(cleanAddress, style: AppTextStyles.bodyMD),
                   if (mapLink != null) ...[
                     const SizedBox(height: 12),
                     const Text('📍 Map Link:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                     SelectableText(mapLink, style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                   ]
                ]
              )
            ),
            const SizedBox(height: 32),
            const Text('Tracking History', style: AppTextStyles.headingLG),
            const SizedBox(height: 24),
            ...backendSteps.asMap().entries.map((e) {
              final step = e.value as Map;
              final label = (step['label'] as String? ?? '').toUpperCase();
              final completed = step['completed'] == true;
              final current = step['current'] == true;
              return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: completed ? AppColors.primary : AppColors.border, 
                                width: completed ? 0 : 2),
                            color: completed
                                ? AppColors.primary
                                : Colors.transparent),
                        child: Icon(
                            completed && !current ? Icons.check : Icons.circle,
                            size: 16,
                            color: completed ? Colors.white : AppColors.border),
                      ),
                      if (e.key < backendSteps.length - 1)
                        Container(
                            width: 2,
                            height: 40,
                            color: completed
                                ? AppColors.primary
                                : AppColors.border.withValues(alpha: 0.5)),
                    ]),
                    const SizedBox(width: 16),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(label,
                          style: current
                              ? const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryDark, letterSpacing: 0.5)
                              : const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
                    ),
                  ]);
            }),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))
                  ],
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.5))),
              child: Row(children: [
                Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(12)),
                    child: const Center(child: Text('🏬', style: TextStyle(fontSize: 24)))),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pickup Progress',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text('${data['progressPercent'] ?? 0}% ready',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primaryDark)),
                  ],
                ),
              ]),
            ),
          ]);
        },
      ),
    );
  }
}
