import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/providers/app_providers.dart';
import '../../core/utils/responsive.dart';

class MyOrdersScreen extends ConsumerWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.r;
    final orders = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('My Orders', style: GoogleFonts.spaceGrotesk(fontSize: r.sp(18), fontWeight: FontWeight.w700)),
        leading: GestureDetector(onTap: () => context.pop(), child: const Icon(Icons.arrow_back_rounded)),
      ),
      body: RefreshIndicator(
        color: AppColors.farmerAccent,
        onRefresh: () async => ref.invalidate(ordersProvider),
        child: orders.when(
          loading: () => ListView.separated(
            padding: EdgeInsets.all(r.rs(16)),
            itemCount: 5,
            separatorBuilder: (_, __) => SizedBox(height: r.rh(12)),
            itemBuilder: (_, __) => const ShimmerBox(height: 90, radius: 16),
          ),
          error: (e, _) => EmptyState(
            emoji: '⚠️',
            title: 'Could not load orders',
            subtitle: e.toString(),
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(ordersProvider),
          ),
          data: (list) {
            if (list.isEmpty) {
              return const EmptyState(
                emoji: '📦',
                title: 'No orders yet',
                subtitle: 'Your orders will appear here once you make a purchase',
              );
            }
            return ListView.separated(
              padding: EdgeInsets.all(r.rs(16)),
              itemCount: list.length,
              separatorBuilder: (_, __) => SizedBox(height: r.rh(12)),
              itemBuilder: (_, i) => _OrderCard(order: list[i]),
            );
          },
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final status       = order['status'] ?? 'Pending';
    final productName  = order['productName'] ?? order['items']?[0]?['product']?['name'] ?? 'Product';
    final supplierName = order['supplierName'] ?? order['items']?[0]?['supplier']?['businessName'] ?? 'Supplier';
    final amount       = (order['totalAmount'] as num?) ?? 0;
    final orderId      = order['id'] ?? '';
    final createdAt    = order['createdAt'] as String?;

    return GestureDetector(
      onTap: () => context.push('/farmer/orders/$orderId/tracking'),
      child: Container(
        padding: EdgeInsets.all(r.rs(16)),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(r.rs(16)),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
          boxShadow: AppColors.softShadow,
        ),
        child: Row(
          children: [
            Container(
              width: r.rs(52), height: 52,
              decoration: BoxDecoration(color: AppColors.farmerTint, borderRadius: BorderRadius.circular(r.rs(14))),
              child: Center(child: Text('📦', style: TextStyle(fontSize: r.sp(26)))),
            ),
            SizedBox(width: r.rs(14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(productName, style: GoogleFonts.inter(fontSize: r.sp(14), fontWeight: FontWeight.w600, color: AppColors.ink), maxLines: 1, overflow: TextOverflow.ellipsis),
                  SizedBox(height: r.rh(2)),
                  Text(supplierName, style: GoogleFonts.inter(fontSize: r.sp(12), color: AppColors.muted)),
                  if (createdAt != null) ...[
                    SizedBox(height: r.rh(4)),
                    Text(_formatDate(createdAt), style: GoogleFonts.inter(fontSize: r.sp(11), color: AppColors.placeholder)),
                  ],
                ],
              ),
            ),
            SizedBox(width: r.rs(8)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(formatRupee(amount), style: GoogleFonts.spaceGrotesk(fontSize: r.sp(15), fontWeight: FontWeight.w700, color: AppColors.ink)),
                SizedBox(height: r.rh(6)),
                BadgeChip.status(status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day} ${_months[d.month - 1]} ${d.year}';
    } catch (_) { return iso; }
  }

  static const _months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
}

