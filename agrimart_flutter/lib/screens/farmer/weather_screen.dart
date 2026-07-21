import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'package:agrimart/l10n/app_localizations.dart';
import '../../core/widgets/app_fallback.dart';
import '../../core/widgets/app_shimmer.dart';
import '../../core/utils/responsive.dart';

class WeatherScreen extends ConsumerWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.r;
    final weather = ref.watch(weatherProvider);
    final district = weather.when(
      data: (d) => d['name'] as String? ?? 'Maharashtra',
      loading: () => 'Maharashtra',
      error: (_, __) => 'Maharashtra',
    );
    final advisory = ref.watch(weatherAdvisoryProvider(district));
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
          title: Text('☀️ ${l10n.weather}'), backgroundColor: AppColors.primary),
      body: weather.when(
        loading: () => const AppShimmerWeatherLayout(),
        error: (e, _) => AppErrorState(
            message: 'Could not load weather data from API',
            onRetry: () => ref.invalidate(weatherProvider)),
        data: (data) => SingleChildScrollView(
            padding: EdgeInsets.all(r.rs(16)),
            child: Column(children: [
              // Main weather card
              Container(
                padding: EdgeInsets.all(r.rs(24)),
                decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Color(0xFF4FC3F7), Color(0xFF0277BD)]),
                    borderRadius: BorderRadius.all(Radius.circular(20))),
                child: Column(children: [
                  Text('☀️', style: TextStyle(fontSize: r.sp(64))),
                  SizedBox(height: r.rh(8)),
                  Text('${data['main']?['temp']?.toStringAsFixed(0) ?? '--'}°C',
                      style: TextStyle(
                          fontSize: r.sp(56),
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  Text('${data['weather']?[0]?['description'] ?? ''}',
                      style: TextStyle(
                          fontSize: r.sp(16),
                          color: Colors.white.withValues(alpha: 0.85))),
                  Text(data['name'] ?? 'Current Location',
                      style: TextStyle(
                          fontSize: r.sp(14),
                          color: Colors.white.withValues(alpha: 0.65))),
                  SizedBox(height: r.rh(20)),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _WeatherStat('💧', l10n.humidity,
                            '${data['main']?['humidity'] ?? '--'}%'),
                        _WeatherStat('💨', l10n.wind,
                            '${data['wind']?['speed'] ?? '--'} m/s'),
                        _WeatherStat('🌡️', l10n.feelsLike,
                            '${data['main']?['feels_like']?.toStringAsFixed(0) ?? '--'}°C'),
                      ]),
                ]),
              ),

              SizedBox(height: r.rh(16)),
              // Farm Advisory
              advisory.when(
                loading: () => const AppShimmerCard(),
                error: (e, _) => AppErrorState(
                  message: 'Farm advisory unavailable',
                  onRetry: () =>
                      ref.invalidate(weatherAdvisoryProvider(district)),
                ),
                data: (adv) {
                  final list = adv['advisories'];
                  return Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(r.rs(16)),
                    decoration: BoxDecoration(
                        color: AppColors.amberSurface,
                        borderRadius: BorderRadius.circular(r.rs(16)),
                        border: Border.all(color: AppColors.amberLight)),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('🌾 ${l10n.farmAdvisory}',
                              style: AppTextStyles.headingMD),
                          SizedBox(height: r.rh(12)),
                          if (list is List && list.isNotEmpty)
                            ...list.map((a) {
                              final tip = a is Map
                                  ? (a['body']?.toString().isNotEmpty == true
                                      ? a['body']?.toString()
                                      : a['tip']?.toString())
                                  : a.toString();
                              final emoji =
                                  a is Map ? a['emoji']?.toString() : '🌱';
                              return Padding(
                                padding: EdgeInsets.only(bottom: r.rh(12)),
                                child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(emoji ?? '🌱',
                                          style: TextStyle(fontSize: r.sp(18))),
                                      SizedBox(width: r.rs(8)),
                                      Expanded(
                                          child: Text(tip ?? '',
                                              style: AppTextStyles.bodyMD)),
                                    ]),
                              );
                            })
                          else
                            Text('No advisory available today.',
                                style: AppTextStyles.bodyMD),
                        ]),
                  );
                },
              ),
              SizedBox(height: r.rh(16)),

              // Min/Max temps
              Container(
                padding: EdgeInsets.all(r.rs(16)),
                decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(r.rs(16)),
                    border: Border.all(color: AppColors.border)),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _TempCard(
                          '🔆',
                          l10n.maxTemp,
                          '${data['main']?['temp_max']?.toStringAsFixed(0) ?? '--'}°C',
                          AppColors.error),
                      Container(width: 1, height: 40, color: AppColors.border),
                      _TempCard(
                          '❄️',
                          l10n.minTemp,
                          '${data['main']?['temp_min']?.toStringAsFixed(0) ?? '--'}°C',
                          AppColors.info),
                    ]),
              ),
            ])),
      ),
    );
  }
}

class _WeatherStat extends StatelessWidget {
  final String emoji, label, value;
  const _WeatherStat(this.emoji, this.label, this.value);
  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Column(children: [
        Text(emoji, style: TextStyle(fontSize: r.sp(20))),
        SizedBox(height: r.rh(4)),
        Text(value,
            style: TextStyle(
                fontSize: r.sp(16),
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        Text(label,
            style: TextStyle(
                fontSize: r.sp(11), color: Colors.white.withValues(alpha: 0.65))),
      ]);
  }
}

class _TempCard extends StatelessWidget {
  final String emoji, label, value;
  final Color color;
  const _TempCard(this.emoji, this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Column(children: [
        Text(emoji, style: TextStyle(fontSize: r.sp(24))),
        SizedBox(height: r.rh(4)),
        Text(value,
            style: TextStyle(
                fontSize: r.sp(20), fontWeight: FontWeight.w800, color: color)),
        Text(label, style: AppTextStyles.caption),
      ]);
  }
}

