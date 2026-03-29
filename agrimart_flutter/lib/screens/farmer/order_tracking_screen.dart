// Quick stub screens for remaining routes
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/app_providers.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/services/api_service.dart';
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
    const steps = ['Order Placed', 'Payment Confirmed', 'Processing', 'Dispatched', 'Out for Delivery', 'Delivered'];
    return Scaffold(
      appBar: AppBar(title: const Text('📍 Order Tracking'), backgroundColor: AppColors.primary),
      body: tracking.when(
        loading: () => const AppShimmerList(),
        error: (e, _) => AppErrorState(message: 'Could not load tracking details', onRetry: () => ref.invalidate(orderTrackingProvider)),
        data: (data) {
          final currentStep = data['currentStep'] as int? ?? 0;
          return ListView(padding: const EdgeInsets.all(24), children: [
            const Text('Order Status', style: AppTextStyles.headingXL),
            const SizedBox(height: 24),
            ...steps.asMap().entries.map((e) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Column(children: [
                Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, color: e.key <= currentStep ? AppColors.primary : AppColors.border), child: Icon(e.key < currentStep ? Icons.check : Icons.circle, size: 16, color: Colors.white)),
                if (e.key < steps.length - 1) Container(width: 2, height: 40, color: e.key < currentStep ? AppColors.primary : AppColors.border),
              ]),
              const SizedBox(width: 16),
              Padding(padding: const EdgeInsets.only(top: 4), child: Text(e.value, style: e.key == currentStep ? AppTextStyles.headingSM.copyWith(color: AppColors.primary) : AppTextStyles.bodyMD)),
            ])).toList(),
            const SizedBox(height: 24),
            if (data['estimatedDelivery'] != null) Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(14)),
              child: Row(children: [const Text('📅', style: TextStyle(fontSize: 24)), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Estimated Delivery', style: AppTextStyles.labelLG), Text(data['estimatedDelivery'].toString(), style: AppTextStyles.headingSM)])])),
          ]);
        },
      ),
    );
  }
}
