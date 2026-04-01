import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_fallback.dart';
import '../../core/widgets/app_shimmer.dart';
import 'mandi_chart_screen.dart';
import 'book_trade_slot_screen.dart';

class MandiPricesScreen extends ConsumerWidget {
  const MandiPricesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weather = ref.watch(weatherProvider);
    final district = weather.when(
      data: (d) => d['name'] as String? ?? 'Nashik',
      loading: () => 'Nashik',
      error: (_, __) => 'Nashik',
    );
    final mandi = ref.watch(mandiProvider(district));

    void refreshMandi() {
      ref.invalidate(weatherProvider);
      ref.invalidate(mandiProvider(district));
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Live Market',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5, fontSize: 22)),
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: () {},
            ),
          ],
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            tabs: [
              Tab(text: 'AGMARKNET LIVE'),
              Tab(text: 'DIRECT BUYERS'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
             mandi.when(
              loading: () => const AppShimmerList(itemCount: 12),
              error: (e, _) => AppErrorState(
                message: 'Market data currently unavailable',
                onRetry: refreshMandi,
              ),
              data: (data) {
                final prices = data['prices'] as List? ?? [];
                if (prices.isEmpty) {
                  return const AppEmptyState(
                    icon: '📉',
                    title: 'Market Closed',
                    subtitle: 'No live rates available for your current region.',
                  );
                }

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      color: AppColors.surface,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.location_on, size: 14, color: AppColors.primary),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(district.toUpperCase(),
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5)),
                              const Text('Live AGMARKNET Feed',
                                  style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.circle, color: AppColors.success, size: 8),
                                SizedBox(width: 4),
                                Text('MARKET OPEN', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(color: AppColors.border, height: 1),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async => refreshMandi(),
                        child: ListView.separated(
                          padding: const EdgeInsets.only(top: 8, bottom: 24),
                          itemCount: prices.length,
                          separatorBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.only(left: 70),
                            child: Divider(height: 1, color: AppColors.border.withValues(alpha: 0.5)),
                          ),
                          itemBuilder: (ctx, i) {
                            final p = prices[i] as Map;
                            final change = (p['change'] as num? ?? 0).toDouble();
                            final isUp = change >= 0;
                            final trendColor = isUp ? const Color(0xFF00C853) : const Color(0xFFFF3D00);

                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MandiChartScreen(cropData: p),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: Center(
                                        child: Text(p['emoji'] as String? ?? '🌾', style: const TextStyle(fontSize: 22)),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(p['crop'] as String? ?? 'Unknown',
                                              style: AppTextStyles.headingMD.copyWith(letterSpacing: -0.2)),
                                          const SizedBox(height: 2),
                                          Text(p['market'] as String? ?? district,
                                              style: AppTextStyles.caption.copyWith(fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '₹${p['price']}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: trendColor,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: trendColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '${isUp ? '+' : ''}${change.toStringAsFixed(2)}%',
                                            style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: trendColor,
                                                letterSpacing: -0.2),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            
            // DIRECT BUYERS TAB CONTENTS
             mandi.when(
              loading: () => const AppShimmerList(itemCount: 8),
              error: (e, _) => AppErrorState(message: 'Could not load buyers', onRetry: refreshMandi),
              data: (data) {
                final prices = data['prices'] as List? ?? [];
                if (prices.isEmpty) return const AppEmptyState(icon: '👩‍🌾', title: 'No Buyers', subtitle: 'No direct buyers available right now.');
                
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMarketInsightCard(),
                      const SizedBox(height: 24),
                      Text('Top Verified Dealers', style: AppTextStyles.headingMD),
                      const SizedBox(height: 16),
                      ...prices.map((p) {
                        final cropName = p['crop'] ?? 'Crop';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              )
                            ],
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.05)),
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 56, height: 56,
                                      decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(16)),
                                      child: Center(child: Text(p['emoji'] as String? ?? '🌾', style: const TextStyle(fontSize: 32))),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Sell $cropName', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              const Icon(Icons.verified, color: Colors.blue, size: 14),
                                              const SizedBox(width: 4),
                                              Text('9 Verified Buyers nearby', style: TextStyle(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('₹${p['price']}+', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary)),
                                        const Text('per quintal', style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.03),
                                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => BookTradeSlotScreen(cropName: cropName, district: district)));
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('VIEW DEALERS & BOOK SLOT', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5)),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.primary),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                );
              }
             )
          ]
        ),
      ),
    );
  }

  Widget _buildMarketInsightCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.primaryShadow,
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Direct Trading', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                SizedBox(height: 4),
                Text('Skip the mandi queues. Sell directly to verified district dealers at competitive rates.', 
                  style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          SizedBox(width: 16),
          CircleAvatar(backgroundColor: Colors.white24, radius: 24, child: Text('🤝', style: TextStyle(fontSize: 24))),
        ],
      ),
    );
  }
}
