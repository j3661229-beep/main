import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_fallback.dart';
import '../../core/widgets/app_shimmer.dart';

class SchemesScreen extends ConsumerWidget {
  const SchemesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schemes = ref.watch(schemesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('🏛️ Govt Schemes'), backgroundColor: AppColors.primary),
      body: schemes.when(
        loading: () => const AppShimmerList(),
        error: (e, _) => AppErrorState(message: 'Could not load government schemes', onRetry: () => ref.invalidate(schemesProvider)),
        data: (list) => list.isEmpty ? const AppEmptyState(icon: '🏛️', title: 'No Schemes Found', subtitle: 'No applicable agriculture schemes available at this moment.') :
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (ctx, i) {
              final s = list[i] as Map;
              return Container(margin: const EdgeInsets.only(bottom: 14), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: const BorderRadius.vertical(top: Radius.circular(15))),
                    child: Row(children: [
                      const Text('🏛️', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(s['title'] ?? '', style: AppTextStyles.headingSM),
                        Text(s['ministry'] ?? '', style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                      ])),
                    ])),
                  Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (s['benefits'] != null) ...[const Text('Benefits', style: AppTextStyles.labelLG), const SizedBox(height: 4), Text(s['benefits'] ?? '', style: AppTextStyles.bodyMD), const SizedBox(height: 10)],
                    if (s['eligibility'] != null) ...[const Text('Eligibility', style: AppTextStyles.labelLG), const SizedBox(height: 4), Text(s['eligibility'] ?? '', style: AppTextStyles.bodyMD.copyWith(color: AppColors.textSecondary)), const SizedBox(height: 10)],
                    if (s['documents'] is List) ...[
                      const Text('Documents Needed', style: AppTextStyles.labelLG),
                      const SizedBox(height: 6),
                      Wrap(spacing: 6, runSpacing: 4, children: (s['documents'] as List).map((d) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.amberSurface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.amberLight)),
                        child: Text(d.toString(), style: AppTextStyles.caption.copyWith(color: AppColors.amber)),
                      )).toList()),
                      const SizedBox(height: 12),
                    ],
                    if (s['applyUrl'] != null) SizedBox(width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('Apply Online →'),
                        onPressed: () async {
                          final url = Uri.parse(s['applyUrl']);
                          if (await canLaunchUrl(url)) launchUrl(url, mode: LaunchMode.externalApplication);
                        },
                      )),
                  ])),
                ]));
            },
          ),
      ),
    );
  }
}
