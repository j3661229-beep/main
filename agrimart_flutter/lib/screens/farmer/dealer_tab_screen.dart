import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/services/api_service.dart';
import '../../data/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/agri_ui.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../core/utils/responsive.dart';

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
    'Mumbai', 'Thane', 'Raigad', 'Ratnagiri', 'Sindhudurg', 'Other',
  ];

  static const Map<String, String> _districtAliases = {
    'konkan division': 'Mumbai', 'konkan': 'Mumbai',
    'mumbai suburban': 'Mumbai', 'greater mumbai': 'Mumbai',
    'brihan mumbai': 'Mumbai', 'navi mumbai': 'Thane',
    'aurangabad': 'Aurangabad', 'parbhani': 'Aurangabad', 'osmanabad': 'Aurangabad',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initDistrict());
  }

  Future<void> _initDistrict() async {
    final farmerDistrict = ref.read(authProvider).user?.farmer?['district'] as String?;
    if (farmerDistrict != null && farmerDistrict.isNotEmpty) {
      setState(() => _district = farmerDistrict);
    }
    await _detectNearestDistrict();
  }

  Future<void> _detectNearestDistrict() async {
    setState(() => _isDetectingLocation = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) { _fallbackDistrict(); return; }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        _fallbackDistrict(); return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)),
      );
      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final detected = (placemarks.first.subAdministrativeArea ?? placemarks.first.administrativeArea ?? '').trim().toLowerCase();
        String? resolved;
        for (final alias in _districtAliases.entries) {
          if (detected.contains(alias.key)) { resolved = alias.value; break; }
        }
        resolved ??= _districts.firstWhere(
          (d) => detected.contains(d.toLowerCase()) || d.toLowerCase().contains(detected.split(' ').first),
          orElse: () => '',
        );
        if (resolved.isNotEmpty && _districts.contains(resolved) && mounted) {
          setState(() => _district = resolved!);
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
    final r = context.r;
    final rates = ref.watch(dealerRatesProvider(_effectiveDistrict));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.farmerAccent,
        onRefresh: () async => ref.invalidate(dealerRatesProvider(_effectiveDistrict)),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(
              child: FarmerTabHeader(
                emoji: '🏪',
                title: 'Dealer Prices',
                subtitle: 'Live buy rates from nearby dealers',
                actions: [
                  GestureDetector(
                    onTap: _isDetectingLocation ? null : _detectNearestDistrict,
                    child: Container(
                      padding: EdgeInsets.all(r.rs(10)),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(r.rs(12))),
                      child: _isDetectingLocation
                          ? SizedBox(width: r.rs(20), height: r.rs(20), child: CircularProgressIndicator(strokeWidth: r.rs(2), color: Colors.white))
                          : Icon(Icons.my_location_rounded, color: Colors.white, size: r.rs(22)),
                    ),
                  ),
                ],
                bottom: Container(
                  padding: EdgeInsets.symmetric(horizontal: r.rs(14), vertical: r.rs(4)),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(r.rs(14)),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _districts.contains(_effectiveDistrict) ? _effectiveDistrict : _districts.first,
                      dropdownColor: AppColors.farmerAccent,
                      iconEnabledColor: Colors.white,
                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: r.sp(15)),
                      isExpanded: true,
                      items: _districts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                      onChanged: (v) { if (v != null) setState(() => _district = v); },
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(r.horizontalPadding, r.rs(16), r.horizontalPadding, r.rs(100)),
              sliver: rates.when(
                loading: () => SliverList(delegate: SliverChildBuilderDelegate((_, __) => Padding(
                  padding: EdgeInsets.only(bottom: r.rs(12)),
                  child: ShimmerBox(height: r.rs(140), radius: 20),
                ), childCount: 4)),
                error: (e, _) => SliverToBoxAdapter(child: EmptyState(
                  emoji: '⚠️',
                  title: 'Could not load rates',
                  subtitle: e.toString(),
                  actionLabel: 'Retry',
                  onAction: () => ref.invalidate(dealerRatesProvider(_effectiveDistrict)),
                )),
                data: (data) {
                  if (data.isEmpty) {
                    return SliverToBoxAdapter(child: EmptyState(
                      emoji: '🏪',
                      title: 'No Dealers in $_effectiveDistrict',
                      subtitle: 'Try selecting a nearby district from the dropdown above.',
                    ));
                  }
                  final Map<String, List<Map>> grouped = {};
                  for (final rate in data) {
                    final crop = rate['cropName'] as String? ?? 'Unknown';
                    grouped.putIfAbsent(crop, () => []).add(rate as Map);
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final entry = grouped.entries.elementAt(i);
                        return Padding(
                          padding: EdgeInsets.only(bottom: r.rs(14)),
                          child: _CropRateCard(
                            cropName: entry.key,
                            rates: entry.value,
                            district: _effectiveDistrict,
                            onBookSlot: (dealerId, _) => context.push('/farmer/trade/book', extra: {
                              'cropName': entry.key,
                              'district': _effectiveDistrict,
                              'dealerId': dealerId,
                            }),
                          ),
                        );
                      },
                      childCount: grouped.length,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CropRateCard extends StatelessWidget {
  final String cropName;
  final List<Map> rates;
  final String district;
  final Function(String, double) onBookSlot;

  const _CropRateCard({required this.cropName, required this.rates, required this.district, required this.onBookSlot});

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
    final r = context.r;
    final bestRateObj = rates.reduce((a, b) => (a['pricePerQuintal'] as num).toDouble() > (b['pricePerQuintal'] as num).toDouble() ? a : b);
    final bestRate = (bestRateObj['pricePerQuintal'] as num).toDouble();
    final bestDealerId = bestRateObj['dealerId'] as String? ?? '';

    return AgriCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(r.rs(16)),
            decoration: BoxDecoration(
              color: AppColors.farmerTint,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(r.rs(18)), topRight: Radius.circular(r.rs(18))),
            ),
            child: Row(
              children: [
                Text(_cropEmoji(cropName), style: TextStyle(fontSize: r.sp(32))),
                SizedBox(width: r.rs(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cropName, style: GoogleFonts.spaceGrotesk(fontSize: r.sp(17), fontWeight: FontWeight.w800, color: AppColors.ink)),
                      Text('${rates.length} dealer${rates.length > 1 ? 's' : ''} buying', style: GoogleFonts.inter(fontSize: r.sp(12), color: AppColors.muted)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(formatRupee(bestRate), style: GoogleFonts.spaceGrotesk(fontSize: r.sp(22), fontWeight: FontWeight.w800, color: AppColors.farmerAccent)),
                    Text('best/quintal', style: GoogleFonts.inter(fontSize: r.sp(10), color: AppColors.muted, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          ...rates.map((rate) {
            final dealerMap = rate['dealer'] as Map?;
            final dealerName = dealerMap?['businessName'] as String? ?? dealerMap?['user']?['name'] as String? ?? 'Local Dealer';
            final price = (rate['pricePerQuintal'] as num).toDouble();
            final isBest = price == bestRate;
            return Padding(
              padding: EdgeInsets.fromLTRB(r.rs(16), r.rs(12), r.rs(16), 0),
              child: Row(
                children: [
                  Container(
                    width: r.rs(40), height: r.rs(40),
                    decoration: BoxDecoration(
                      color: isBest ? AppColors.farmerTint : AppColors.background,
                      borderRadius: BorderRadius.circular(r.rs(12)),
                    ),
                    child: Center(child: Text('🤝', style: TextStyle(fontSize: r.sp(20)))),
                  ),
                  SizedBox(width: r.rs(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(child: Text(dealerName, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: r.sp(14), color: AppColors.ink), overflow: TextOverflow.ellipsis)),
                            if (isBest) ...[
                              SizedBox(width: r.rs(6)),
                              BadgeChip(label: 'BEST', color: AppColors.farmerAccent, textColor: Colors.white),
                            ],
                          ],
                        ),
                        Text('Verified Dealer', style: GoogleFonts.inter(fontSize: r.sp(11), color: AppColors.muted)),
                      ],
                    ),
                  ),
                  Text(
                    '${formatRupee(price)}/q',
                    style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, fontSize: r.sp(15), color: isBest ? AppColors.farmerAccent : AppColors.ink),
                  ),
                ],
              ),
            );
          }),
          Padding(
            padding: EdgeInsets.all(r.rs(16)),
            child: FarmerActionButton(
              label: 'Book Delivery Slot',
              emoji: '📅',
              onTap: () => onBookSlot(bestDealerId, bestRate),
            ),
          ),
        ],
      ),
    );
  }
}
