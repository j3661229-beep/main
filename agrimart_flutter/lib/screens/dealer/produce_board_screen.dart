import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/services/api_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../core/utils/responsive.dart';

final _produceBoardCropProvider  = StateProvider<String?>((ref) => null);
final _produceListingsProvider   = FutureProvider.family<List, String?>((ref, crop) async {
  return ApiService.instance.getProduceListings(crop: crop);
});

class ProduceBoardScreen extends ConsumerWidget {
  const ProduceBoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.r;
    final selectedCrop = ref.watch(_produceBoardCropProvider);
    final listings     = ref.watch(_produceListingsProvider(selectedCrop));
    final crops        = ['All', ...AppConstants.popularCrops.map((c) => c['name']!)];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Produce Board', style: GoogleFonts.spaceGrotesk(fontSize: r.sp(18), fontWeight: FontWeight.w700)),
        leading: GestureDetector(onTap: () => context.pop(), child: const Icon(Icons.arrow_back_rounded)),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          FilterChipRow(
            options: crops,
            selected: selectedCrop ?? 'All',
            onSelect: (v) => ref.read(_produceBoardCropProvider.notifier).state = v == 'All' ? null : v,
            accent: AppColors.dealerAccent,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.dealerAccent,
              onRefresh: () async => ref.invalidate(_produceListingsProvider),
              child: listings.when(
                loading: () => ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 5,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, __) => const ShimmerBox(height: 120, radius: 16),
                ),
                error: (_, __) => const EmptyState(emoji: '⚠️', title: 'Could not load listings', subtitle: 'Check your connection and try again'),
                data: (list) {
                  if (list.isEmpty) return const EmptyState(emoji: '🌾', title: 'No listings available', subtitle: 'Farmers will list their produce here');
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _ProduceListing(listing: list[i]),
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

class _ProduceListing extends StatelessWidget {
  final Map listing;
  const _ProduceListing({required this.listing});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final crop         = listing['crop'] ?? 'Crop';
    final quantity     = listing['quantity'] ?? 0;
    final farmerName   = listing['farmerName'] ?? listing['farmer']?['name'] ?? 'Farmer';
    final village      = listing['village'] ?? listing['farmer']?['village'] ?? '';
    final askingPrice  = (listing['expectedPrice'] ?? listing['askingPrice'] as num?) ?? 0;
    final distance     = listing['distance'];
    final listingId    = listing['id'] ?? '';

    // Get emoji for crop
    final cropEmoji = AppConstants.popularCrops.firstWhere(
      (c) => c['name']?.toLowerCase() == crop.toLowerCase(),
      orElse: () => {'emoji': '🌾'},
    )['emoji'] ?? '🌾';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: AppColors.dealerTint, borderRadius: BorderRadius.circular(14)),
                child: Center(child: Text(cropEmoji, style: TextStyle(fontSize: r.sp(28)))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(crop, style: GoogleFonts.spaceGrotesk(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 13, color: AppColors.muted),
                        const SizedBox(width: 3),
                        Text(farmerName, style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
                        if (village.isNotEmpty) ...[
                          Text(' · ', style: GoogleFonts.inter(color: AppColors.muted)),
                          Text(village, style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (distance != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.dealerTint, borderRadius: BorderRadius.circular(20)),
                  child: Text('${distance}km', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.dealerAccent)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Stat(label: 'Quantity', value: '$quantity qtl'),
              _Stat(label: 'Asking Price', value: '${formatRupee(askingPrice)}/qtl', valueColor: AppColors.dealerAccent),
              _Stat(label: 'Total Value', value: formatRupee((askingPrice as num) * (quantity as num))),
            ],
          ),
          const SizedBox(height: 14),
          AppButton(
            label: 'Make Offer',
            onTap: () => context.push('/dealer/make-offer', extra: listing),
            color: AppColors.dealerAccent,
            height: 44,
            icon: Icons.handshake_outlined,
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _Stat({required this.label, required this.value, this.valueColor});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted)),
      Text(value, style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w700, color: valueColor ?? AppColors.ink)),
    ],
  );
}

