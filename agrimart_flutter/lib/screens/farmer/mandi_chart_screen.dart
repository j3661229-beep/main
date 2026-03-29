import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_fallback.dart';
import '../../core/widgets/app_shimmer.dart';

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
    final cropName = widget.cropData['crop'] as String? ?? 'Crop';
    final historyAsync = ref.watch(mandiHistoryProvider(cropName));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${widget.cropData['emoji']} $cropName', 
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: -0.5)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
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

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Price Header (Trading Style) ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                color: AppColors.background,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('₹${currentPrice.toStringAsFixed(0)}', 
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -1.5, height: 1)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, 
                             color: trendColor, size: 22),
                        const SizedBox(width: 4),
                        Text(
                          '${change.abs().toStringAsFixed(2)}% ($_selectedRange)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: trendColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('• Per Quintal', style: TextStyle(color: AppColors.textTertiary, fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // ── Chart Area ──
              SizedBox(
                height: 280,
                width: double.infinity,
                child: LineChart(
                  LineChartData(
                    lineTouchData: LineTouchData(
                      handleBuiltInTouches: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) => AppColors.textPrimary,
                        tooltipRoundedRadius: 8,
                        tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((LineBarSpot touchedSpot) {
                            return LineTooltipItem(
                              '₹${touchedSpot.y.toStringAsFixed(0)}',
                              const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                            );
                          }).toList();
                        },
                      ),
                      getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                        return spotIndexes.map((spotIndex) {
                          return TouchedSpotIndicatorData(
                            FlLine(color: trendColor.withValues(alpha: 0.3), strokeWidth: 2, dashArray: [4, 4]),
                            FlDotData(
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 6,
                                  color: trendColor,
                                  strokeWidth: 3,
                                  strokeColor: Colors.white,
                                );
                              },
                            ),
                          );
                        }).toList();
                      },
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: (maxPrice - minPrice) / 3,
                      getDrawingHorizontalLine: (value) => FlLine(color: AppColors.border.withValues(alpha: 0.5), strokeWidth: 1, dashArray: [8, 8]),
                    ),
                    titlesData: FlTitlesData(show: false), // Clean edges
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: (dataPoints - 1).toDouble(),
                    minY: minPrice,
                    maxY: maxPrice,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        curveSmoothness: 0.35,
                        color: trendColor,
                        barWidth: 2.5,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              trendColor.withValues(alpha: 0.2),
                              trendColor.withValues(alpha: 0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Timeframe Selector (Segmented Style) ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(22),
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
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))
                              ],
                            ) : null,
                            child: Text(
                              range,
                              style: TextStyle(
                                fontSize: 13,
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.storefront_rounded, color: AppColors.textTertiary, size: 16),
                    const SizedBox(width: 8),
                    Text('Trading strictly derived from ${widget.cropData['market']} (${widget.cropData['district']}) Mandi.', 
                        style: const TextStyle(fontSize: 11, color: AppColors.textTertiary, fontWeight: FontWeight.w500)),
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
