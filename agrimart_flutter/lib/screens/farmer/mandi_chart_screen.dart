import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_fallback.dart';
import '../../core/widgets/app_shimmer.dart';
import '../../core/widgets/mandi_chart.dart';
import '../../core/utils/responsive.dart';

final mandiHistoryProvider = FutureProvider.family<Map, String>((ref, crop) async {
  return ApiService.instance.getCropHistory(crop);
});

class MandiChartScreen extends ConsumerStatefulWidget {
  final Map cropData;
  const MandiChartScreen({super.key, required this.cropData});

  @override
  ConsumerState<MandiChartScreen> createState() => _MandiChartScreenState();
}

class _MandiChartScreenState extends ConsumerState<MandiChartScreen> {
  String _selectedRange = '5D';

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final cropName = widget.cropData['crop'] as String? ?? 'Crop';
    final historyAsync = ref.watch(mandiHistoryProvider(cropName));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${widget.cropData['emoji']} $cropName', 
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: r.sp(18), letterSpacing: -0.5)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(r.rh(1)),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => AppErrorState(message: 'Could not load chart data', onRetry: () => ref.refresh(mandiHistoryProvider(cropName))),
        data: (data) {
          final history = data['history'] as List? ?? [];
          final currentPrice = (widget.cropData['price'] as num? ?? 0).toDouble();
          final change = (widget.cropData['change'] as num? ?? 0).toDouble();
          final isUp = change >= 0;
          final trendColor = isUp ? const Color(0xFF00C853) : const Color(0xFFFF3D00); // Standard trading green/red

          // Mocking data based on range since backend only returns 7 days for now
          List<FlSpot> spots = [];
          double minPrice = double.infinity;
          double maxPrice = 0;
          
          int dataPoints = _selectedRange == '1D' ? 12 : _selectedRange == '5D' ? 30 : _selectedRange == '1M' ? 30 : 60;
          
          for (int i = 0; i < dataPoints; i++) {
            double noise = (currentPrice * 0.05) * (i % 3 == 0 ? 1 : -1) * (i / dataPoints);
            double price = currentPrice - noise - (isUp ? (dataPoints - i) * 6 : -(dataPoints - i) * 6);
            if (i == dataPoints - 1) price = currentPrice;
            if (price < minPrice) minPrice = price;
            if (price > maxPrice) maxPrice = price;
            spots.add(FlSpot(i.toDouble(), price));
          }

          minPrice = minPrice * 0.98;
          maxPrice = maxPrice * 1.02;
          
          if (maxPrice == minPrice) {
            minPrice = (minPrice > 0 ? minPrice : 100) * 0.9;
            maxPrice = (maxPrice > 0 ? maxPrice : 100) * 1.1;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Price Header (Trading Style) ──
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(r.rs(24), r.rh(32), r.rs(24), r.rh(16)),
                color: AppColors.background,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('₹${currentPrice.toStringAsFixed(0)}', 
                        style: TextStyle(fontSize: r.sp(48), fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -1.5, height: 1)),
                    SizedBox(height: r.rh(8)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, 
                             color: trendColor, size: r.sp(22)),
                        SizedBox(width: r.rs(4)),
                        Text(
                          '${change.abs().toStringAsFixed(2)}% ($_selectedRange)',
                          style: TextStyle(
                            fontSize: r.sp(18),
                            fontWeight: FontWeight.w700,
                            color: trendColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(width: r.rs(8)),
                        Text('• Per Quintal', style: TextStyle(color: AppColors.textTertiary, fontSize: r.sp(13), fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: r.rh(12)),
              
              // ── Chart Area (Replaced with Custom Widget for precision) ──
              Padding(
                padding: EdgeInsets.symmetric(horizontal: r.rs(16)),
                child: MandiPriceChart(history: history, cropName: cropName),
              ),

              SizedBox(height: r.rh(32)),

              // ── Timeframe Selector (Segmented Style) ──
              Padding(
                padding: EdgeInsets.symmetric(horizontal: r.rs(24)),
                child: Container(
                  height: r.rh(44),
                  padding: EdgeInsets.all(r.rs(4)),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(r.rs(22)),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: ['1D', '5D', '1M', '6M', '1Y'].map((range) {
                      final isSelected = _selectedRange == range;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedRange = range),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            alignment: Alignment.center,
                            decoration: isSelected ? BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(r.rs(18)),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: r.rs(8), offset: Offset(0, 2))
                              ],
                            ) : null,
                            child: Text(
                              range,
                              style: TextStyle(
                                fontSize: r.sp(13),
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected ? AppColors.textPrimary : AppColors.textTertiary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              
              const Spacer(),
              
              // ── Market Info ──
              Padding(
                padding: EdgeInsets.symmetric(horizontal: r.rs(24), vertical: r.rh(24)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.storefront_rounded, color: AppColors.textTertiary, size: r.sp(16)),
                    SizedBox(width: r.rs(8)),
                    Text('Trading strictly derived from ${widget.cropData['market']} (${widget.cropData['district']}) Mandi.', 
                        style: TextStyle(fontSize: r.sp(11), color: AppColors.textTertiary, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

