import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shimmer.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(
          title: const Text('📦 My Orders'),
          backgroundColor: AppColors.primary),
      body: orders.when(
        loading: () => const AppShimmerList(itemCount: 6),
        error: (e, _) => const Center(child: Text('Could not load orders')),
        data: (list) => list.isEmpty
            ? Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    const Text('📦', style: TextStyle(fontSize: 64)),
                    const SizedBox(height: 16),
                    const Text('No orders yet', style: AppTextStyles.headingLG),
                    const SizedBox(height: 8),
                    TextButton(
                        onPressed: () => context.push('/farmer/shop'),
                        child: const Text('Start Shopping →')),
                  ]))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (ctx, i) {
                  final o = list[i] as Map;
                  final status = o['status'] as String? ?? 'PENDING';
                  final Color statusColor = status == 'DELIVERED'
                      ? AppColors.success
                      : status == 'CANCELLED'
                          ? AppColors.error
                          : AppColors.amber;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(12)),
                          child: const Center(
                              child:
                                  Text('📦', style: TextStyle(fontSize: 22)))),
                      title: Text(
                          '#${(o['id'] as String).substring((o['id'] as String).length - 8).toUpperCase()}',
                          style: AppTextStyles.headingSM),
                      subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('₹${o['totalAmount']}',
                                style: AppTextStyles.priceSmall
                                    .copyWith(fontSize: 14)),
                            Text(
                                o['createdAt']?.toString().split('T').first ??
                                    '',
                                style: AppTextStyles.caption),
                          ]),
                      trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20)),
                                child: Text(status.replaceAll('_', ' '),
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: statusColor))),
                            const SizedBox(height: 4),
                            const Text('Track →', style: AppTextStyles.caption),
                          ]),
                      onTap: () =>
                          context.push('/farmer/orders/${o['id']}/tracking'),
                    ),
                  );
                }),
      ),
    );
  }
}
