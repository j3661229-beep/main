import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agrimart/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/widgets/app_fallback.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../data/providers/app_providers.dart';
import '../../../data/providers/auth_provider.dart';
import '../../core/utils/responsive.dart';

class AdvisoryScreen extends ConsumerWidget {
  const AdvisoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.r;
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authProvider).user;
    final district = user?.district ?? user?.effectiveDistrict ?? 'Nashik';
    final advisory = ref.watch(weatherAdvisoryProvider(district));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.farmAdvisory,
          style: GoogleFonts.spaceGrotesk(
            fontSize: r.sp(18),
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.farmerAccent,
              onRefresh: () async {
                ref.invalidate(weatherProvider);
                ref.invalidate(weatherAdvisoryProvider(district));
              },
              child: advisory.when(
                loading: () => ListView(
                  padding: EdgeInsets.all(r.rs(16)),
                  children: [
                    const ShimmerBox(height: 140, radius: 20),
                    SizedBox(height: r.rs(16)),
                    ...List.generate(4, (_) => Padding(
                      padding: EdgeInsets.only(bottom: r.rs(12)),
                      child: const ShimmerBox(height: 130, radius: 18),
                    )),
                  ],
                ),
                error: (e, _) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(r.rs(16)),
                  children: [
                    _WeatherHeroCard(district: district),
                    SizedBox(height: r.rs(16)),
                    AppErrorState(
                      message: l10n.noAdvisoryToday,
                      onRetry: () {
                        ref.invalidate(weatherProvider);
                        ref.invalidate(weatherAdvisoryProvider(district));
                      },
                    ),
                    SizedBox(height: r.rs(16)),
                    ..._fallbackTips.map((t) => Padding(
                      padding: EdgeInsets.only(bottom: r.rs(12)),
                      child: _AdvisoryCard(tip: t),
                    )),
                  ],
                ),
                data: (payload) {
                  final map = Map<String, dynamic>.from(payload);
                  final list = (map['advisories'] as List?)
                          ?.map((e) => Map<String, dynamic>.from(e as Map))
                          .toList() ??
                      [];
                  final weather = map['weather'] is Map
                      ? Map<String, dynamic>.from(map['weather'] as Map)
                      : null;

                  if (list.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.all(r.rs(16)),
                      children: [
                        if (weather != null) _WeatherHeroCard(weather: weather, district: district),
                        if (weather != null) SizedBox(height: r.rs(16)),
                        _SectionHeader(title: l10n.todaysAdvisory, subtitle: district),
                        SizedBox(height: r.rs(12)),
                        ..._fallbackTips.map((t) => Padding(
                          padding: EdgeInsets.only(bottom: r.rs(12)),
                          child: _AdvisoryCard(tip: t),
                        )),
                      ],
                    );
                  }

                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(r.rs(16)),
                    children: [
                      if (weather != null) _WeatherHeroCard(weather: weather, district: district),
                      if (weather != null) SizedBox(height: r.rs(16)),
                      _SectionHeader(
                        title: l10n.todaysAdvisory,
                        subtitle: '$district · ${list.length} tips',
                      ),
                      SizedBox(height: r.rs(12)),
                      ...list.map((tip) => Padding(
                        padding: EdgeInsets.only(bottom: r.rs(12)),
                        child: _AdvisoryCard(tip: tip),
                      )),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _fallbackTips = [
  {
    'type': 'weather',
    'emoji': '🌧️',
    'title': 'Rain Alert',
    'body': 'Heavy rainfall expected next 2 days. Avoid pesticide application and ensure proper drainage in fields.',
    'severity': 'alert',
    'color': 0xFFB3402F,
  },
  {
    'type': 'sowing',
    'emoji': '🌱',
    'title': 'Sowing Window',
    'body': 'Optimal time to sow Kharif crops. Soybean and Cotton sowing recommended between 15 June – 30 June.',
    'severity': 'info',
    'color': 0xFF3D6B35,
  },
  {
    'type': 'irrigation',
    'emoji': '💧',
    'title': 'Irrigation Guidance',
    'body': 'Maintain 5cm water level in paddy fields. For drip-irrigated crops, reduce frequency due to high humidity.',
    'severity': 'warning',
    'color': 0xFFD97706,
  },
  {
    'type': 'price',
    'emoji': '📈',
    'title': 'Onion Price Alert',
    'body': 'Onion prices at Nashik APMC have risen 12% this week. Good time to sell stored produce.',
    'severity': 'info',
    'color': 0xFFA85C1A,
  },
];

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.spaceGrotesk(fontSize: r.sp(16), fontWeight: FontWeight.w700, color: AppColors.ink)),
              Text(subtitle, style: GoogleFonts.inter(fontSize: r.sp(12), color: AppColors.muted)),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: r.rs(10), vertical: r.rs(5)),
          decoration: BoxDecoration(
            color: AppColors.farmerTint,
            borderRadius: BorderRadius.circular(r.rs(20)),
          ),
          child: Text('AI', style: GoogleFonts.inter(fontSize: r.sp(11), fontWeight: FontWeight.w700, color: AppColors.farmerAccent)),
        ),
      ],
    );
  }
}

class _WeatherHeroCard extends StatelessWidget {
  final Map<String, dynamic>? weather;
  final String district;
  const _WeatherHeroCard({this.weather, required this.district});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final temp = weather?['temperature'] ?? weather?['temp'] ?? weather?['main']?['temp'];
    final humidity = weather?['humidity'] ?? weather?['main']?['humidity'];
    final condition = weather?['condition'] ?? weather?['description'] ?? weather?['weather']?[0]?['main'] ?? 'Clear';
    final city = weather?['location'] ?? weather?['city'] ?? weather?['name'] ?? district;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(r.rs(20)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D5A27), Color(0xFF3D6B35)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(r.rs(20)),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('🌤️', style: TextStyle(fontSize: r.sp(28))),
              SizedBox(width: r.rs(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(city.toString(), style: GoogleFonts.spaceGrotesk(fontSize: r.sp(16), fontWeight: FontWeight.w700, color: Colors.white)),
                    Text(condition.toString(), style: GoogleFonts.inter(fontSize: r.sp(12), color: Colors.white70)),
                  ],
                ),
              ),
              if (temp != null)
                Text(
                  '${(temp as num).round()}°C',
                  style: GoogleFonts.spaceGrotesk(fontSize: r.sp(32), fontWeight: FontWeight.w800, color: Colors.white),
                ),
            ],
          ),
          if (humidity != null) ...[
            SizedBox(height: r.rs(14)),
            Row(
              children: [
                _WeatherChip(icon: Icons.water_drop_outlined, label: 'Humidity ${(humidity as num).round()}%'),
                SizedBox(width: r.rs(8)),
                _WeatherChip(icon: Icons.location_on_outlined, label: district),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _WeatherChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _WeatherChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: r.rs(10), vertical: r.rs(6)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(r.rs(20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: r.rs(14), color: Colors.white70),
          SizedBox(width: r.rs(4)),
          Text(label, style: GoogleFonts.inter(fontSize: r.sp(11), color: Colors.white)),
        ],
      ),
    );
  }
}

class _AdvisoryCard extends StatelessWidget {
  final Map<String, dynamic> tip;
  const _AdvisoryCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final color = Color((tip['color'] as int?) ?? 0xFF3D6B35);
    final severity = tip['severity']?.toString() ?? 'info';
    final title = tip['title']?.toString() ?? '';
    final body = tip['body']?.toString() ?? '';

    return Container(
      padding: EdgeInsets.all(r.rs(18)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(r.rs(18)),
        border: Border.all(color: color.withValues(alpha: 0.28)),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: r.rs(46),
                height: r.rs(46),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(r.rs(14)),
                ),
                child: Center(child: Text(tip['emoji']?.toString() ?? '📋', style: TextStyle(fontSize: r.sp(24)))),
              ),
              SizedBox(width: r.rs(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.spaceGrotesk(fontSize: r.sp(15), fontWeight: FontWeight.w700, color: AppColors.ink),
                    ),
                    SizedBox(height: r.rs(4)),
                    _SeverityBadge(severity: severity, color: color),
                  ],
                ),
              ),
            ],
          ),
          if (body.isNotEmpty) ...[
            SizedBox(height: r.rs(12)),
            Text(
              body,
              style: GoogleFonts.inter(fontSize: r.sp(13), color: AppColors.muted, height: 1.55),
            ),
          ],
        ],
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  final String severity;
  final Color color;
  const _SeverityBadge({required this.severity, required this.color});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final label = switch (severity) {
      'alert' => 'ALERT',
      'warning' => 'WARNING',
      _ => 'TIP',
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: r.rs(8), vertical: r.rs(3)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(r.rs(6)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: r.sp(10), fontWeight: FontWeight.w700, color: color, letterSpacing: 0.5),
      ),
    );
  }
}
