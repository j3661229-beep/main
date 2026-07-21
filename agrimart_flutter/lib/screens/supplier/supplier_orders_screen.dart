import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/providers/app_providers.dart';
import '../../../data/services/api_service.dart';
import '../../core/utils/responsive.dart';

final _supplierOrderStatusProvider = StateProvider<String?>((ref) => null);

class SupplierOrdersScreen extends ConsumerWidget {
  const SupplierOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.r;
    final status = ref.watch(_supplierOrderStatusProvider);
    final orders = ref.watch(supplierOrdersProvider(status));
    const statuses = ['All', 'PENDING', 'PROCESSING', 'DISPATCHED', 'DELIVERED'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Orders', style: GoogleFonts.spaceGrotesk(fontSize: r.sp(18), fontWeight: FontWeight.w700)),
        leading: GestureDetector(onTap: () => context.pop(), child: const Icon(Icons.arrow_back_rounded)),
      ),
      body: Column(
        children: [
          SizedBox(height: r.rh(8)),
          FilterChipRow(
            options: statuses,
            selected: status ?? 'All',
            onSelect: (v) => ref.read(_supplierOrderStatusProvider.notifier).state = v == 'All' ? null : v,
            accent: AppColors.supplierAccent,
          ),
          SizedBox(height: r.rh(12)),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.supplierAccent,
              onRefresh: () async => ref.invalidate(supplierOrdersProvider),
              child: orders.when(
                loading: () => ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: r.rs(16)),
                  itemCount: 5,
                  separatorBuilder: (_, __) => SizedBox(height: r.rh(12)),
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
                  if (list.isEmpty) {
                    return const EmptyState(
                      emoji: '📦',
                      title: 'No orders found',
                      subtitle: 'Orders will appear here when farmers purchase your products',
                    );
                  }
                  return ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: r.rs(16)),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => SizedBox(height: r.rh(12)),
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
    _status = (widget.order['status'] ?? 'PENDING').toString();
  }

  String get _farmerName {
    final o = widget.order;
    return o['farmerName']
        ?? o['order']?['farmer']?['user']?['name']
        ?? o['farmer']?['name']
        ?? 'Farmer';
  }

  String get _productName {
    final o = widget.order;
    return o['productName'] ?? o['product']?['name'] ?? 'Product';
  }

  num get _amount {
    final o = widget.order;
    return (o['totalAmount'] ?? o['amount'] ?? ((o['price'] as num?) ?? 0) * ((o['quantity'] as num?) ?? 1)) as num;
  }

  Future<void> _updateStatus(String nextStatus, String successLabel) async {
    setState(() => _isUpdating = true);
    try {
      await ApiService.instance.updateOrderStatus(widget.order['id'].toString(), nextStatus);
      if (mounted) {
        setState(() {
          _status = nextStatus;
          _isUpdating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successLabel), backgroundColor: AppColors.success),
        );
      }
      ref.invalidate(supplierOrdersProvider);
      ref.invalidate(supplierDashboardProvider);
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    }
  }

  String? get _nextAction {
    switch (_status.toUpperCase()) {
      case 'PENDING':
      case 'PAYMENT_CONFIRMED':
        return 'PROCESSING';
      case 'PROCESSING':
        return 'DISPATCHED';
      case 'DISPATCHED':
      case 'OUT_FOR_DELIVERY':
        return 'DELIVERED';
      default:
        return null;
    }
  }

  String get _actionLabel {
    switch (_nextAction) {
      case 'PROCESSING':
        return 'Confirm & Process';
      case 'DISPATCHED':
        return 'Mark Dispatched';
      case 'DELIVERED':
        return 'Mark Delivered';
      default:
        return 'Update';
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final o = widget.order;
    final qty = o['quantity'] ?? o['qty'] ?? '-';
    final orderId = o['id']?.toString() ?? '';

    return Container(
      padding: EdgeInsets.all(r.rs(16)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(r.rs(16)),
        border: Border.all(
          color: _status == 'PENDING'
              ? AppColors.supplierAccent.withValues(alpha: 0.4)
              : AppColors.border.withValues(alpha: 0.6),
        ),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: r.rs(44),
                height: r.rh(44),
                decoration: BoxDecoration(color: AppColors.supplierTint, borderRadius: BorderRadius.circular(r.rs(12))),
                child: Center(child: Text('🌾', style: TextStyle(fontSize: r.sp(22)))),
              ),
              SizedBox(width: r.rs(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_farmerName, style: GoogleFonts.inter(fontSize: r.sp(14), fontWeight: FontWeight.w600, color: AppColors.ink)),
                    Text(_productName, style: GoogleFonts.inter(fontSize: r.sp(12), color: AppColors.muted)),
                  ],
                ),
              ),
              BadgeChip.status(_status),
            ],
          ),
          SizedBox(height: r.rh(12)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _InfoChip(label: 'Qty', value: '$qty units'),
              _InfoChip(label: 'Amount', value: formatRupee(_amount)),
              _InfoChip(label: 'Order #', value: orderId.length > 8 ? orderId.substring(0, 8) : orderId),
            ],
          ),
          if (_nextAction != null) ...[
            SizedBox(height: r.rh(14)),
            AppButton(
              label: _actionLabel,
              onTap: () => _updateStatus(_nextAction!, 'Order updated to $_nextAction'),
              isLoading: _isUpdating,
              color: AppColors.supplierAccent,
              height: r.rh(42),
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
  Widget build(BuildContext context) {
    final r = context.r;
    return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: GoogleFonts.inter(fontSize: r.sp(11), color: AppColors.muted)),
      Text(value, style: GoogleFonts.spaceGrotesk(fontSize: r.sp(13), fontWeight: FontWeight.w600, color: AppColors.ink)),
    ],
  );
  }
}
