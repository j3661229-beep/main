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
                
                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: prices.length,
                  itemBuilder: (ctx, i) {
                     final p = prices[i] as Map;
                     final cropName = p['crop'] ?? 'Crop';
                     return Container(
                       margin: const EdgeInsets.only(bottom: 16),
                       decoration: BoxDecoration(
                         gradient: const LinearGradient(colors: [Colors.white, Color(0xFFF8FAFC)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                         borderRadius: BorderRadius.circular(24),
                         border: Border.all(color: AppColors.primary.withValues(alpha: 0.1), width: 2),
                         boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 8))]
                       ),
                       child: Padding(
                         padding: const EdgeInsets.all(20),
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Row(
                               children: [
                                  Text(p['emoji'] as String? ?? '🌾', style: const TextStyle(fontSize: 28)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Sell $cropName Direct', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                                        Text('Top buyers in $district', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                                      ],
                                    )
                                  ),
                               ]
                             ),
                             const SizedBox(height: 20),
                             SizedBox(
                               width: double.infinity,
                               child: ElevatedButton(
                                 onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => BookTradeSlotScreen(cropName: cropName, district: district)));
                                 },
                                 style: ElevatedButton.styleFrom(
                                   backgroundColor: AppColors.primaryDark,
                                   foregroundColor: Colors.white,
                                   padding: const EdgeInsets.symmetric(vertical: 16),
                                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                   elevation: 0,
                                 ),
                                 child: const Row(
                                   mainAxisAlignment: MainAxisAlignment.center,
                                   children: [
                                     Text('View Dealers & Book Slot', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                                     SizedBox(width: 8),
                                     Icon(Icons.arrow_forward_rounded, size: 18)
                                   ]
                                 )
                               )
                             )
                           ]
                         )
                       )
                     );
                  }
                );
              }
             )
          ]
        ),
      ),
    );
  }
}
