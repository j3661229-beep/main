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
                  return GestureDetector(
                    onTap: () => context.push('/farmer/orders/${o['id']}/tracking'),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                          border: Border.all(color: AppColors.border.withValues(alpha: 0.5))),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                  color: AppColors.primarySurface,
                                  borderRadius: BorderRadius.circular(16)),
                              child: const Center(
                                  child: Text('📦', style: TextStyle(fontSize: 26)))),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                        '#${(o['id'] as String).substring((o['id'] as String).length - 8).toUpperCase()}',
                                        style: AppTextStyles.headingSM.copyWith(letterSpacing: -0.2)),
                                    Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                            color: statusColor.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(20)),
                                        child: Text(status.replaceAll('_', ' '),
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor, letterSpacing: 0.5))),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Total Amount', style: TextStyle(fontSize: 10, color: AppColors.textTertiary, fontWeight: FontWeight.w600)),
                                          Text('₹${o['totalAmount']}',
                                              style: AppTextStyles.priceSmall.copyWith(fontSize: 16)),
                                        ]),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(o['createdAt']?.toString().split('T').first ?? '',
                                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text('Track Order', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
                                            const SizedBox(width: 4),
                                            const Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.primary),
                                          ],
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
