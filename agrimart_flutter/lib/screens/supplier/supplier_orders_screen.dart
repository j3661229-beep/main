import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/providers/app_providers.dart';
import '../../../data/services/api_service.dart';

final _supplierOrderStatusProvider = StateProvider<String?>((ref) => null);

class SupplierOrdersScreen extends ConsumerWidget {
  const SupplierOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(_supplierOrderStatusProvider);
    final orders = ref.watch(supplierOrdersProvider(status));
    final statuses = ['All', 'PENDING', 'CONFIRMED', 'SHIPPED', 'DELIVERED'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Orders', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w700)),
        leading: GestureDetector(onTap: () => context.pop(), child: const Icon(Icons.arrow_back_rounded)),
      ),
      body: Column(
        children: [
          // Status filter
          const SizedBox(height: 8),
          FilterChipRow(
            options: statuses,
            selected: status ?? 'All',
            onSelect: (v) => ref.read(_supplierOrderStatusProvider.notifier).state = v == 'All' ? null : v,
            accent: AppColors.supplierAccent,
          ),
          const SizedBox(height: 12),

          Expanded(
            child: RefreshIndicator(
              color: AppColors.supplierAccent,
              onRefresh: () async => ref.invalidate(supplierOrdersProvider),
              child: orders.when(
                loading: () => ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 5,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, __) => const ShimmerBox(height: 100, radius: 16),
                ),
                error: (e, _) => EmptyState(
                  emoji: '⚠️',
                  title: 'Could not load orders',
                  subtitle: e.toString(),
                  actionLabel: 'Retry',
                  onAction: () => ref.invalidate(supplierOrdersProvider),
                ),
                data: (list) {
                  if (list.isEmpty) return const EmptyState(
                    emoji: '📦',
                    title: 'No orders found',
                    subtitle: 'Orders will appear here when farmers purchase your products',
                  );
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _SupplierOrderCard(order: list[i]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupplierOrderCard extends ConsumerStatefulWidget {
  final Map order;
  const _SupplierOrderCard({required this.order});
  @override
  ConsumerState<_SupplierOrderCard> createState() => _SupplierOrderCardState();
}

class _SupplierOrderCardState extends ConsumerState<_SupplierOrderCard> {
  late String _status;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _status = widget.order['status'] ?? 'PENDING';
  }

  Future<void> _confirmOrder() async {
    setState(() => _isUpdating = true);
    try {
      await ApiService.instance.updateOrderStatus(widget.order['id'], 'CONFIRMED');
      setState(() { _status = 'CONFIRMED'; _isUpdating = false; });
      ref.invalidate(supplierOrdersProvider);
    } catch (e) {
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final farmerName  = o['farmerName']  ?? o['farmer']?['name']  ?? 'Farmer';
    final productName = o['productName'] ?? o['product']?['name'] ?? 'Product';
    final qty         = o['quantity'] ?? o['qty'] ?? '-';
    final amount      = (o['totalAmount'] ?? o['amount'] as num?) ?? 0;
    final orderId     = o['id'] ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _status == 'PENDING' ? AppColors.supplierAccent.withValues(alpha: 0.4) : AppColors.border.withValues(alpha: 0.6)),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: AppColors.supplierTint, borderRadius: BorderRadius.circular(12)),
                child: const Center(child: Text('🌾', style: TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(farmerName, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
                    Text(productName, style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
                  ],
                ),
              ),
              BadgeChip.status(_status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _InfoChip(label: 'Qty', value: '$qty units'),
              _InfoChip(label: 'Amount', value: formatRupee(amount)),
              _InfoChip(label: 'Order #', value: orderId.length > 8 ? orderId.substring(0, 8) : orderId),
            ],
          ),
          if (_status == 'PENDING') ...[
            const SizedBox(height: 14),
            AppButton(
              label: 'Confirm Order',
              onTap: _confirmOrder,
              isLoading: _isUpdating,
              color: AppColors.supplierAccent,
              height: 42,
              icon: Icons.check_circle_outline_rounded,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label, value;
  const _InfoChip({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted)),
      Text(value, style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
    ],
  );
}

