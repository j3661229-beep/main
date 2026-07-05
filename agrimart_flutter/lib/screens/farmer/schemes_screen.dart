import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/agri_ui.dart';
import '../../core/widgets/app_fallback.dart';
import '../../core/widgets/app_shimmer.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../core/utils/responsive.dart';

class SchemesScreen extends ConsumerWidget {
  const SchemesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.r;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            SliverAppBar(
              expandedHeight: 130,
              pinned: true,
              backgroundColor: AppColors.info,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(gradient: AppColors.supplierGradient),
                  padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('🏛️', style: TextStyle(fontSize: r.sp(28))),
                      const SizedBox(height: 6),
                      Text('Govt Schemes', style: GoogleFonts.spaceGrotesk(fontSize: r.sp(24), fontWeight: FontWeight.w800, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('Subsidies, loans & insurance', style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              bottom: TabBar(
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
                unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                tabs: const [
                  Tab(text: 'For You'),
                  Tab(text: 'All Schemes'),
                ],
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _SchemeList(provider: eligibleSchemesProvider, emptyTitle: 'No matched schemes', emptySubtitle: 'Complete your farm profile for better matches'),
              _SchemeList(provider: schemesProvider, emptyTitle: 'No Schemes Found', emptySubtitle: 'Check back later for new government programs'),
            ],
          ),
        ),
      ),
    );
  }
}

class _SchemeList extends ConsumerWidget {
  final FutureProvider<List> provider;
  final String emptyTitle;
  final String emptySubtitle;

  const _SchemeList({
    required this.provider,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.r;
    final schemes = ref.watch(provider);
    return schemes.when(
      loading: () => const AppShimmerList(),
      error: (e, _) => AppErrorState(message: 'Could not load schemes', onRetry: () => ref.invalidate(provider)),
      data: (list) => list.isEmpty
          ? EmptyState(emoji: '🏛️', title: emptyTitle, subtitle: emptySubtitle)
          : ListView.builder(
              padding: EdgeInsets.fromLTRB(r.horizontalPadding, 16, r.horizontalPadding, 32),
              itemCount: list.length,
              itemBuilder: (ctx, i) => Padding(
                padding: EdgeInsets.only(bottom: i < list.length - 1 ? 12 : 0),
                child: _SchemeCard(scheme: list[i] as Map),
              ),
            ),
    );
  }
}

class _SchemeCard extends StatelessWidget {
  final Map scheme;
  const _SchemeCard({required this.scheme});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return AgriCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.infoTint,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(14)),
                  child: Center(child: Text('🏛️', style: TextStyle(fontSize: r.sp(24)))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(scheme['title'] ?? '', style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w700)),
                      Text(scheme['ministry'] ?? '', style: GoogleFonts.inter(fontSize: 12, color: AppColors.info, fontWeight: FontWeight.w500)),
                      if (scheme['matchScore'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: BadgeChip(label: 'Match ${scheme['matchScore']}%', color: AppColors.successTint, textColor: AppColors.success),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (scheme['benefits'] != null) ...[
                  Text('Benefits', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted)),
                  const SizedBox(height: 4),
                  Text(scheme['benefits'] ?? '', style: GoogleFonts.inter(fontSize: 13, height: 1.4)),
                  const SizedBox(height: 12),
                ],
                if (scheme['eligibility'] != null) ...[
                  Text('Eligibility', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted)),
                  const SizedBox(height: 4),
                  Text(scheme['eligibility'] ?? '', style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted, height: 1.4)),
                  const SizedBox(height: 12),
                ],
                if (scheme['applyUrl'] != null)
                  AppButton(
                    label: 'Apply Online',
                    icon: Icons.open_in_new_rounded,
                    height: 44,
                    isOutlined: true,
                    color: AppColors.info,
                    onTap: () async {
                      final url = Uri.parse(scheme['applyUrl']);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
