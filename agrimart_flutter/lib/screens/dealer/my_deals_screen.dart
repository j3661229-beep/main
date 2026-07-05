import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/services/api_service.dart';
import '../../core/utils/responsive.dart';

final _myDealsProvider = FutureProvider<List>((ref) async {
  return ApiService.instance.getDeals();
});

class MyDealsScreen extends ConsumerWidget {
  const MyDealsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.r;
    final deals = ref.watch(_myDealsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('My Deals', style: GoogleFonts.spaceGrotesk(fontSize: r.sp(18), fontWeight: FontWeight.w700)),
        leading: GestureDetector(onTap: () => context.pop(), child: const Icon(Icons.arrow_back_rounded)),
      ),
      body: RefreshIndicator(
        color: AppColors.dealerAccent,
        onRefresh: () async => ref.invalidate(_myDealsProvider),
        child: deals.when(
          loading: () => ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: 5,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, __) => const ShimmerBox(height: 110, radius: 16),
          ),
          error: (e, _) => EmptyState(
            emoji: '⚠️',
            title: 'Could not load deals',
            subtitle: e.toString(),
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(_myDealsProvider),
          ),
          data: (list) {
            if (list.isEmpty) return EmptyState(
              emoji: '🤝',
              title: 'No deals yet',
              subtitle: 'Browse the produce board to make your first offer',
              actionLabel: 'Browse Produce',
              onAction: () => context.push('/dealer/produce-board'),
            );
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _DealCard(deal: list[i]),
            );
          },
        ),
      ),
    );
  }
}

class _DealCard extends StatelessWidget {
  final Map deal;
  const _DealCard({required this.deal});

  String _displayStatus(String? s) {
    switch (s?.toUpperCase()) {
      case 'PENDING':   return 'Awaiting Reply';
      case 'CONFIRMED': return 'Confirmed';
      case 'COMPLETED': return 'Completed';
      case 'CANCELLED': return 'Cancelled';
      default:          return s ?? 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final crop       = deal['crop']        ?? deal['listing']?['crop'] ?? 'Crop';
    final farmer     = deal['farmerName']  ?? deal['listing']?['farmerName'] ?? deal['listing']?['farmer']?['name'] ?? 'Farmer';
    final qty        = (deal['quantity']   ?? deal['listing']?['quantity'] as num?) ?? 0;
    final offered    = (deal['offerPrice'] as num?) ?? 0;
    final status     = deal['status'] ?? 'PENDING';
    final pickupDate = deal['pickupDate'] as String?;
    final advance    = (deal['advanceAmount'] as num?) ?? 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(color: AppColors.dealerTint, borderRadius: BorderRadius.circular(14)),
                child: Center(child: Text('🌾', style: TextStyle(fontSize: r.sp(26)))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(crop, style: GoogleFonts.spaceGrotesk(fontSize: r.sp(16), fontWeight: FontWeight.w700, color: AppColors.ink)),
                    Row(children: [
                      const Icon(Icons.person_outline, size: 13, color: AppColors.muted),
                      const SizedBox(width: 3),
                      Text(farmer, style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
                    ]),
                  ],
                ),
              ),
              BadgeChip.status(_displayStatus(status)),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _DealStat('Quantity', '$qty qtl'),
              _DealStat('Offered', '${formatRupee(offered)}/qtl'),
              _DealStat('Total', formatRupee((offered as num) * (qty as num))),
            ],
          ),
          if (advance > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppColors.successTint, borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline, color: AppColors.success, size: 14),
                  const SizedBox(width: 6),
                  Text('Advance Paid: ${formatRupee(advance)}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.success)),
                ],
              ),
            ),
          ],
          if (pickupDate != null) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.muted),
              const SizedBox(width: 6),
              Text('Pickup: ${_formatDate(pickupDate)}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
            ]),
          ],
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${d.day} ${m[d.month-1]} ${d.year}';
    } catch (_) { return iso; }
  }
}

class _DealStat extends StatelessWidget {
  final String label, value;
  const _DealStat(this.label, this.value);
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted)),
      Text(value, style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
    ],
  );
}

