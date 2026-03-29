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
      appBar: AppBar(
          title: const Text('📍 Order Tracking'),
          backgroundColor: AppColors.primary),
      body: tracking.when(
        loading: () => const AppShimmerList(),
        error: (e, _) => AppErrorState(
            message: 'Could not load tracking details',
            onRetry: () => ref.invalidate(orderTrackingProvider)),
        data: (data) {
          final backendSteps = (data['tracking'] as List? ?? []);
          return ListView(padding: const EdgeInsets.all(24), children: [
            const Text('Order Status', style: AppTextStyles.headingXL),
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
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: completed
                                ? AppColors.primary
                                : AppColors.border),
                        child: Icon(
                            completed && !current ? Icons.check : Icons.circle,
                            size: 16,
                            color: Colors.white),
                      ),
                      if (e.key < backendSteps.length - 1)
                        Container(
                            width: 2,
                            height: 40,
                            color: completed
                                ? AppColors.primary
                                : AppColors.border),
                    ]),
                    const SizedBox(width: 16),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(label,
                          style: current
                              ? AppTextStyles.headingSM
                                  .copyWith(color: AppColors.primary)
                              : AppTextStyles.bodyMD),
                    ),
                  ]);
            }),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                const Text('📈', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Delivery Progress',
                        style: AppTextStyles.labelLG),
                    Text('${data['progressPercent'] ?? 0}% complete',
                        style: AppTextStyles.headingSM),
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
