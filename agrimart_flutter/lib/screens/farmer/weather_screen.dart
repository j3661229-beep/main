import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_fallback.dart';
import '../../core/widgets/app_shimmer.dart';

class WeatherScreen extends ConsumerWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Default to Nashik coords
    final weather = ref.watch(weatherProvider);
    final String district = weather.value?['name'] ?? 'Maharashtra';
    final advisory = ref.watch(weatherAdvisoryProvider(district));

    return Scaffold(
      appBar: AppBar(title: const Text('☀️ Weather'), backgroundColor: AppColors.primary),
      body: weather.when(
        loading: () => const AppShimmerCard(),
        error: (e, _) => AppErrorState(message: 'Could not load weather data from API', onRetry: () => ref.invalidate(weatherProvider)),
        data: (data) => SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
          // Main weather card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF4FC3F7), Color(0xFF0277BD)]), borderRadius: BorderRadius.all(Radius.circular(20))),
            child: Column(children: [
              const Text('☀️', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 8),
              Text('${data['main']?['temp']?.toStringAsFixed(0) ?? '--'}°C', style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w800, color: Colors.white)),
              Text('${data['weather']?[0]?['description'] ?? ''}', style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.85))),
              Text(data['name'] ?? 'Current Location', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.65))),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _WeatherStat('💧', 'Humidity', '${data['main']?['humidity'] ?? '--'}%'),
                _WeatherStat('💨', 'Wind', '${data['wind']?['speed'] ?? '--'} m/s'),
                _WeatherStat('🌡️', 'Feels Like', '${data['main']?['feels_like']?.toStringAsFixed(0) ?? '--'}°C'),
              ]),
            ]),
          ),

          const SizedBox(height: 16),

          // Farm Advisory
          advisory.whenOrNull(data: (adv) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.amberSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.amberLight)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('🌾 Farm Advisory', style: AppTextStyles.headingMD),
              const SizedBox(height: 8),
              if (adv['advisories'] is List && (adv['advisories'] as List).isNotEmpty)
                ...(adv['advisories'] as List).map((a) {
                  if (a is Map) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(a['emoji']?.toString() ?? '• ', style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(a['tip']?.toString() ?? '', style: AppTextStyles.bodyMD)),
                      ]),
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('🌱 ', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(a.toString(), style: AppTextStyles.bodyMD)),
                      ]),
                    );
                  }
                })
              else
                const Text('No advisory available today.', style: AppTextStyles.bodyMD),
            ]),
          )) ?? const SizedBox.shrink(),

          const SizedBox(height: 16),

          // Min/Max temps
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _TempCard('🔆', 'Max Temp', '${data['main']?['temp_max']?.toStringAsFixed(0) ?? '--'}°C', AppColors.error),
              Container(width: 1, height: 40, color: AppColors.border),
              _TempCard('❄️', 'Min Temp', '${data['main']?['temp_min']?.toStringAsFixed(0) ?? '--'}°C', AppColors.info),
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
  Widget build(BuildContext context) => Column(children: [
    Text(emoji, style: const TextStyle(fontSize: 20)),
    const SizedBox(height: 4),
    Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
    Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.65))),
  ]);
}

class _TempCard extends StatelessWidget {
  final String emoji, label, value;
  final Color color;
  const _TempCard(this.emoji, this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(emoji, style: const TextStyle(fontSize: 24)),
    const SizedBox(height: 4),
    Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
    Text(label, style: AppTextStyles.caption),
  ]);
}
