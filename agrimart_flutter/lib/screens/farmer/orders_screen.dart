import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_fallback.dart';
import '../../core/widgets/app_shimmer.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/farmer'),
          ),
          title: const Text('📦 My Orders', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          backgroundColor: AppColors.primary,
          elevation: 0,
          centerTitle: true),
      body: orders.when(
        loading: () => const AppShimmerList(itemCount: 6),
        error: (e, _) => const Center(child: Text('Could not load orders')),
        data: (list) => list.isEmpty
            ? AppEmptyState(
                icon: '📦',
                title: 'No orders yet',
                subtitle: 'Browse the shop to buy seeds, fertilizers, and more.',
                actionLabel: 'Start Shopping →',
                onAction: () => context.push('/farmer/shop'),
              )
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
                  return GestureDetector(
                    onTap: () => context.push('/farmer/orders/${o['id']}/tracking'),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: AppColors.softShadow,
                          border: Border.all(color: AppColors.border.withValues(alpha: 0.4))),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                  color: AppColors.primarySurface,
                                  borderRadius: BorderRadius.circular(16)),
                              child: const Center(
                                  child: Text('📦', style: TextStyle(fontSize: 28)))),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                        'Order #${(o['id'] as String).substring((o['id'] as String).length - 6).toUpperCase()}',
                                        style: AppTextStyles.headingSM.copyWith(letterSpacing: -0.4, fontWeight: FontWeight.w900)),
                                    Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                            color: statusColor.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(20)),
                                        child: Text(status.replaceAll('_', ' '),
                                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: statusColor, letterSpacing: 0.5))),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('TOTAL AMOUNT', style: TextStyle(fontSize: 9, color: AppColors.textTertiary, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                                          const SizedBox(height: 2),
                                          Text('₹${o['totalAmount']}',
                                              style: AppTextStyles.priceSmall.copyWith(fontSize: 18, fontWeight: FontWeight.w900)),
                                        ]),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(o['createdAt']?.toString().split('T').first ?? '',
                                            style: TextStyle(fontSize: 11, color: AppColors.textTertiary, fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.05),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Text('Track', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w900)),
                                              SizedBox(width: 4),
                                              Icon(Icons.arrow_forward_ios, size: 8, color: AppColors.primary),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
      ),
    );
  }
}
