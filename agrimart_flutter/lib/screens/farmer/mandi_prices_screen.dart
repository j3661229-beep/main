import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_fallback.dart';
import '../../core/widgets/app_shimmer.dart';

class MandiPricesScreen extends ConsumerWidget {
  const MandiPricesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Attempting to get dynamically from weather if available, else Nashik
    final weather = ref.watch(weatherProvider);
    final String district = weather.value?['name'] ?? 'Nashik';
    final mandi = ref.watch(mandiProvider(district));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('📈 Mandi Prices', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(mandiProvider),
          ),
        ],
      ),
      body: mandi.when(
        loading: () => const AppShimmerList(itemCount: 8),
        error: (e, _) => AppErrorState(
          message: 'Could not load mandi prices',
          onRetry: () => ref.invalidate(mandiProvider),
        ),
        data: (data) {
          final prices = data['prices'] as List? ?? [];
          
          if (prices.isEmpty) {
            return const AppEmptyState(
              icon: '🌾',
              title: 'No rates available',
              subtitle: 'Check back later for today\'s market rates',
            );
          }

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                color: AppColors.primarySurface,
                child: Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text('Market: $district', style: AppTextStyles.labelLG.copyWith(color: AppColors.primaryDark)),
                    const Spacer(),
                    const Text('Updated Today', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => ref.invalidate(mandiProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: prices.length,
                    itemBuilder: (ctx, i) {
                      final p = prices[i] as Map;
                      final up = (p['change'] as num? ?? 0) >= 0;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                              child: Text(p['emoji'] as String? ?? '🌾', style: const TextStyle(fontSize: 28)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p['crop'] as String? ?? 'Unknown', style: AppTextStyles.headingMD),
                                  const SizedBox(height: 4),
                                  Text('₹${p['price']}/quintal', style: AppTextStyles.priceSmall.copyWith(fontSize: 16, color: AppColors.primary)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (up ? AppColors.success : AppColors.error).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${up ? '↑' : '↓'} ${(p['change'] as num? ?? 0).abs().toStringAsFixed(1)}%',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: up ? AppColors.success : AppColors.error),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(p['market'] as String? ?? district, style: AppTextStyles.caption.copyWith(fontSize: 10)),
                              ],
                            ),
                          ],
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
    );
  }
}
