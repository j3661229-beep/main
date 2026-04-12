import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../data/services/api_service.dart';
import '../../data/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_fallback.dart';
import '../../core/widgets/app_shimmer.dart';

// Provider for dealer crop rates — district only, all crops
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
  String _district = '';
  bool _isDetectingLocation = false;

  static const _districts = [
    'Dhule', 'Nashik', 'Pune', 'Jalgaon', 'Aurangabad',
    'Ahmednagar', 'Kolhapur', 'Solapur', 'Nagpur', 'Amravati',
    'Konkan Division', 'Mumbai', 'Mumbai Suburban', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initDistrict());
  }

  /// Auto-detect district from GPS, fallback to farmer profile, then default
  Future<void> _initDistrict() async {
    // First use farmer's profile district if available
    final farmerDistrict = ref.read(authProvider).user?.farmer?['district'] as String?;
    if (farmerDistrict != null && farmerDistrict.isNotEmpty) {
      setState(() => _district = farmerDistrict);
    }

    // Then try to get GPS-based district (overrides profile if successful)
    await _detectNearestDistrict();
  }

  Future<void> _detectNearestDistrict() async {
    setState(() => _isDetectingLocation = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _fallbackDistrict();
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        _fallbackDistrict();
        return;
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        // subAdministrativeArea is typically the district
        final detected = place.subAdministrativeArea ?? place.administrativeArea ?? '';

        // Match to known districts (fuzzy)
        final matched = _districts.firstWhere(
          (d) => detected.toLowerCase().contains(d.toLowerCase()) || d.toLowerCase().contains(detected.toLowerCase().split(' ').first),
          orElse: () => '',
        );

        if (matched.isNotEmpty && mounted) {
          setState(() => _district = matched);
        } else {
          _fallbackDistrict();
        }
      } else {
        _fallbackDistrict();
      }
    } catch (_) {
      _fallbackDistrict();
    } finally {
      if (mounted) setState(() => _isDetectingLocation = false);
    }
  }

  void _fallbackDistrict() {
    if (_district.isEmpty) setState(() => _district = _districts.first);
  }

  String get _effectiveDistrict => _district.isNotEmpty ? _district : _districts.first;

  @override
  Widget build(BuildContext context) {
    final rates = ref.watch(dealerRatesProvider(_effectiveDistrict));

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
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Dealer Prices', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                            Text('Nearby dealers • Live rates', style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      // Location detect button
                      GestureDetector(
                        onTap: _isDetectingLocation ? null : _detectNearestDistrict,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _isDetectingLocation
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.my_location, color: Colors.white, size: 20),
                        ),
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
                        value: _districts.contains(_effectiveDistrict) ? _effectiveDistrict : _districts.first,
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

                  if (_isDetectingLocation) ...[
                    const SizedBox(height: 10),
                    const Row(
                      children: [
                        Icon(Icons.location_searching, color: Colors.white54, size: 14),
                        SizedBox(width: 6),
                        Text('Finding nearest dealers…', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ],
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
                onRetry: () => ref.invalidate(dealerRatesProvider(_effectiveDistrict)),
              ),
              data: (data) {
                if (data.isEmpty) {
                  return AppEmptyState(
                    icon: '🏪',
                    title: 'No Dealers in $_effectiveDistrict',
                    subtitle: 'Try selecting a nearby district from the dropdown.',
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
                            width: 8, height: 8,
                            decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Live rates • $_effectiveDistrict district',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...grouped.entries.map((entry) => _CropRateCard(
                        cropName: entry.key,
                        rates: entry.value,
                        district: _effectiveDistrict,
                        onBookSlot: (dealerId, rate) {
                          context.push('/farmer/trade/book', extra: {
                            'cropName': entry.key,
                            'district': _effectiveDistrict,
                            'dealerId': dealerId,
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
    final bestRateObj = rates.reduce((a, b) => (a['pricePerQuintal'] as num).toDouble() > (b['pricePerQuintal'] as num).toDouble() ? a : b);
    final bestRate = (bestRateObj['pricePerQuintal'] as num).toDouble();
    final bestDealerId = bestRateObj['dealerId'] as String? ?? '';

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
            final dealerMap = rate['dealer'] as Map?;
            final dealerName = dealerMap?['businessName'] as String?
                ?? dealerMap?['user']?['name'] as String?
                ?? 'Local Dealer';
            final price = (rate['pricePerQuintal'] as num).toDouble();
            final isBest = price == bestRate;

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
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
                            Flexible(child: Text(dealerName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis)),
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
                onPressed: () => onBookSlot(bestDealerId, bestRate),
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
