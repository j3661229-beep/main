import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/services/api_service.dart';

final _advisoryProvider = FutureProvider.family<List, String>((ref, location) async {
  return ApiService.instance.getAdvisory(location: location.isEmpty ? null : location);
});

class AdvisoryScreen extends ConsumerWidget {
  const AdvisoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final location = user?.district ?? '';
    final advisory = ref.watch(_advisoryProvider(location));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Advisory', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w700)),
        leading: GestureDetector(onTap: () => context.pop(), child: const Icon(Icons.arrow_back_rounded)),
      ),
      body: RefreshIndicator(
        color: AppColors.farmerAccent,
        onRefresh: () async => ref.invalidate(_advisoryProvider),
        child: advisory.when(
          loading: () => ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, __) => const ShimmerBox(height: 120, radius: 16),
          ),
          error: (_, __) => _FallbackAdvisory(),
          data: (list) {
            if (list.isEmpty) return _FallbackAdvisory();
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _AdvisoryCard(tip: list[i]),
            );
          },
        ),
      ),
    );
  }
}

class _FallbackAdvisory extends StatelessWidget {
  final _tips = const [
    {'type': 'weather', 'emoji': '🌧️', 'title': 'Rain Alert', 'body': 'Heavy rainfall expected next 2 days. Avoid pesticide application and ensure proper drainage in fields.', 'color': 0xFF1D4E63},
    {'type': 'sowing', 'emoji': '🌱', 'title': 'Sowing Window', 'body': 'Optimal time to sow Kharif crops. Soybean and Cotton sowing recommended between 15 June – 30 June.', 'color': 0xFF3D6B35},
    {'type': 'irrigation', 'emoji': '💧', 'title': 'Irrigation Guidance', 'body': 'Maintain 5cm water level in paddy fields. For drip-irrigated crops, reduce frequency due to high humidity.', 'color': 0xFF0277BD},
    {'type': 'price', 'emoji': '📈', 'title': 'Onion Price Alert', 'body': 'Onion prices at Nashik APMC have risen 12% this week to ₹1,840/qtl. Good time to sell stored produce.', 'color': 0xFFA85C1A},
  ];

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.all(16),
    itemCount: _tips.length,
    separatorBuilder: (_, __) => const SizedBox(height: 12),
    itemBuilder: (_, i) => _AdvisoryCard(tip: _tips[i]),
  );
}

class _AdvisoryCard extends StatelessWidget {
  final Map tip;
  const _AdvisoryCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    final color = Color(tip['color'] as int? ?? 0xFF3D6B35);
    final tint  = color.withValues(alpha: 0.1);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text(tip['emoji'] as String? ?? '📋', style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tip['title'] as String? ?? '', style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
                    Text(_typeLabel(tip['type'] as String?), style: GoogleFonts.inter(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(tip['body'] as String? ?? '', style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted, height: 1.6)),
        ],
      ),
    );
  }

  String _typeLabel(String? type) {
    switch (type) {
      case 'weather':    return 'WEATHER ALERT';
      case 'sowing':     return 'SOWING WINDOW';
      case 'irrigation': return 'IRRIGATION TIP';
      case 'price':      return 'MANDI PRICE';
      default:           return 'ADVISORY';
    }
  }
}

