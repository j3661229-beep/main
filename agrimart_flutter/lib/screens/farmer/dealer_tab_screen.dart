import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/services/api_service.dart';
import '../../data/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_fallback.dart';
import '../../core/widgets/app_shimmer.dart';

// Provider for dealer crop rates
final dealerRatesProvider = FutureProvider.family<List, String>((ref, district) async {
  if (district.isEmpty) return [];
  return ApiService.instance.getDealerRates(district: district);
});

class DealerTabScreen extends ConsumerStatefulWidget {
  const DealerTabScreen({super.key});

  @override
  ConsumerState<DealerTabScreen> createState() => _DealerTabScreenState();
}

class _DealerTabScreenState extends ConsumerState<DealerTabScreen> {
  String _district = 'Dhule';

  static const _districts = [
    'Dhule', 'Nashik', 'Pune', 'Jalgaon', 'Aurangabad',
    'Ahmednagar', 'Kolhapur', 'Solapur', 'Nagpur', 'Amravati',
    'Konkan Division', 'Mumbai', 'Mumbai Suburban', 'Other',
  ];


  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final farmerDistrict = auth.user?.farmer?['district'] as String?;
    final effectiveDistrict = _district.isNotEmpty ? _district : (farmerDistrict ?? 'Dhule');

    final rates = ref.watch(dealerRatesProvider(effectiveDistrict));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF3949AB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text('🏪', style: TextStyle(fontSize: 26)),
                      ),
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dealer Prices', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                          Text('Live crop buying rates', style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // District selector
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: effectiveDistrict,
                        dropdownColor: const Color(0xFF283593),
                        iconEnabledColor: Colors.white,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                        isExpanded: true,
                        items: _districts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _district = v);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: rates.when(
              loading: () => Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: List.generate(5, (_) => _RateShimmer()),
                ),
              ),
              error: (e, _) => AppErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(dealerRatesProvider(effectiveDistrict)),
              ),
              data: (data) {
                if (data.isEmpty) {
                  return const AppEmptyState(
                    icon: '🏪',
                    title: 'No Dealer Rates Found',
                    subtitle: 'Try selecting a different district.',
                  );
                }

                // Group by crop name
                final Map<String, List<Map>> grouped = {};
                for (final rate in data) {
                  final crop = rate['cropName'] as String? ?? 'Unknown';
                  grouped.putIfAbsent(crop, () => []).add(rate as Map);
                }

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Live rates • ${effectiveDistrict} district',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...grouped.entries.map((entry) => _CropRateCard(
                        cropName: entry.key,
                        rates: entry.value,
                        district: effectiveDistrict,
                        onBookSlot: (dealerId, rate) {
                          context.push('/farmer/trade/book', extra: {
                            'cropName': entry.key,
                            'district': effectiveDistrict,
                          });
                        },
                      )),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CropRateCard extends StatelessWidget {
  final String cropName;
  final List<Map> rates;
  final String district;
  final Function(String, double) onBookSlot;

  const _CropRateCard({
    required this.cropName,
    required this.rates,
    required this.district,
    required this.onBookSlot,
  });

  String _cropEmoji(String crop) {
    final c = crop.toLowerCase();
    if (c.contains('onion') || c.contains('kanda')) return '🧅';
    if (c.contains('tomato') || c.contains('tamatar')) return '🍅';
    if (c.contains('wheat') || c.contains('gehun')) return '🌾';
    if (c.contains('cotton') || c.contains('kapas')) return '☁️';
    if (c.contains('soybean') || c.contains('soja')) return '🫘';
    if (c.contains('rice') || c.contains('chawal')) return '🍚';
    if (c.contains('potato') || c.contains('batata')) return '🥔';
    return '🌱';
  }

  @override
  Widget build(BuildContext context) {
    final bestRate = rates.map((r) => (r['pricePerQuintal'] as num).toDouble()).reduce((a, b) => a > b ? a : b);
    final lowestRate = rates.map((r) => (r['pricePerQuintal'] as num).toDouble()).reduce((a, b) => a < b ? a : b);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Crop header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Text(_cropEmoji(cropName), style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cropName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      Text('${rates.length} dealer${rates.length > 1 ? 's' : ''} buying'),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₹${bestRate.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary)),
                    const Text('best/quintal', style: TextStyle(fontSize: 10, color: AppColors.textTertiary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),

          // Dealer list
          ...rates.map((rate) {
            final dealerName = (rate['dealer'] as Map?)?['businessName'] as String? ??
                (rate['dealer'] as Map?)?['user']?['name'] as String? ?? 'Local Dealer';
            final price = (rate['pricePerQuintal'] as num).toDouble();
            final isBest = price == bestRate;

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isBest ? AppColors.primarySurface : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(child: Text('🤝', style: TextStyle(fontSize: 20))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(dealerName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
                            if (isBest) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                                child: const Text('BEST', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ],
                        ),
                        const Text('Verified Dealer', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                      ],
                    ),
                  ),
                  Text('₹${price.toStringAsFixed(0)}/q', style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: isBest ? AppColors.primary : AppColors.textPrimary,
                  )),
                ],
              ),
            );
          }),

          // Book slot button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => onBookSlot('', bestRate),
                icon: const Text('📅', style: TextStyle(fontSize: 16)),
                label: const Text('Book Delivery Slot', style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RateShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              AppShimmer(width: 40, height: 40, borderRadius: 12),
              SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                AppShimmer(width: 100, height: 18, borderRadius: 6),
                SizedBox(height: 6),
                AppShimmer(width: 70, height: 14, borderRadius: 4),
              ])),
              AppShimmer(width: 60, height: 28, borderRadius: 8),
            ]),
            SizedBox(height: 16),
            AppShimmer(width: double.infinity, height: 38, borderRadius: 12),
          ],
        ),
      ),
    );
  }
}
