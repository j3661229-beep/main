import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MandiPriceChart extends StatelessWidget {
  final List<dynamic> history;
  final String cropName;

  const MandiPriceChart({super.key, required this.history, required this.cropName});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox(height: 200, child: Center(child: Text('No history available')));

    final spots = history.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), (e.value['price'] as num).toDouble());
    }).toList();

    final lastPrice = history.last['price'] as num;
    final firstPrice = history.first['price'] as num;
    final isUp = lastPrice >= firstPrice;
    final color = isUp ? const Color(0xFF00C853) : const Color(0xFFD50000);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$cropName Price Trend',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '₹$lastPrice',
                  style: GoogleFonts.inter(color: color, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => Colors.black.withOpacity(0.8),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '₹${spot.y.toInt()}',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [color.withOpacity(0.2), color.withOpacity(0.0)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Past 7 days (APMC Data)',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }
}
