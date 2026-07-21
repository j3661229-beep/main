import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/providers/app_language_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../data/providers/app_providers.dart';
import '../../data/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/agri_ui.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../core/utils/responsive.dart';

class MandiNewsScreen extends ConsumerWidget {
  const MandiNewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.r;
    final newsAsync = ref.watch(mandiNewsProvider);
    final user = ref.watch(authProvider).user;
    final lang = ref.watch(appLanguageProvider);
    final district = user?.effectiveDistrict ?? 'Nashik';

    String subtitle(String code) {
      if (code == 'mr') return '$district • ${lang.aiName} बातम्या';
      if (code == 'hi') return '$district • ${lang.aiName} समाचार';
      return '$district • ${lang.aiName} news';
    }

    return AgriScreen(
      title: 'Mandi News',
      subtitle: subtitle(ref.watch(localeProvider).languageCode),
      emoji: '📰',
      accent: AppColors.farmerAccent,
      onRefresh: () async => ref.invalidate(mandiNewsProvider),
      body: newsAsync.when(
        loading: () => ListView.separated(
          padding: EdgeInsets.symmetric(horizontal: r.horizontalPadding, vertical: r.rs(16)),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: 4,
          separatorBuilder: (_, __) => SizedBox(height: r.rs(16)),
          itemBuilder: (_, __) => ShimmerBox(height: r.rs(220), radius: r.rs(20)),
        ),
        error: (e, _) => EmptyState(
          emoji: '⚠️',
          title: 'Could not load news',
          subtitle: e.toString(),
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(mandiNewsProvider),
        ),
        data: (news) {
          if (news.isEmpty) {
            return const EmptyState(
              emoji: '📰',
              title: 'No news right now',
              subtitle: 'We will notify you when there are market updates in your area.',
            );
          }
          return ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: r.horizontalPadding, vertical: r.rs(16)),
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: news.length,
            separatorBuilder: (_, __) => SizedBox(height: r.rs(16)),
            itemBuilder: (context, index) {
              final item = news[index] as Map;
              final isLocal = (item['district'] == user?.effectiveDistrict) || (item['state'] == user?.state);
              return _NewsCard(item: item, isLocal: isLocal);
            },
          );
        },
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final Map item;
  final bool isLocal;

  const _NewsCard({required this.item, required this.isLocal});

  String _timeAgo(String? timestamp) {
    if (timestamp == null) return 'Recently';
    try {
      final dt = DateTime.parse(timestamp);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (_) {
      return 'Recently';
    }
  }

  void _openDetails(BuildContext context) async {
    final link = item['link']?.toString();
    if (link != null && link.isNotEmpty) {
      context.push('/webview', extra: {
        'url': link,
        'title': item['title'] ?? 'News Article',
      });
      return;
    }

    // Show modal bottom sheet for internal news
    final r = context.r;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(r.rs(24))),
          ),
          child: Column(
            children: [
              SizedBox(height: r.rs(12)),
              Container(
                width: r.rs(48),
                height: r.rs(5),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(r.rs(4)),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: EdgeInsets.all(r.rs(20)),
                  children: [
                    if (item['imageUrl'] != null && item['imageUrl'].toString().isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(r.rs(16)),
                        child: CachedNetworkImage(
                          imageUrl: item['imageUrl'],
                          height: r.rs(220),
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => ShimmerBox(height: r.rs(220), radius: r.rs(16)),
                          errorWidget: (_, __, ___) => const SizedBox(),
                        ),
                      ),
                    SizedBox(height: r.rs(20)),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: r.rs(10), vertical: r.rs(4)),
                          decoration: BoxDecoration(
                            color: AppColors.farmerAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(r.rs(8)),
                          ),
                          child: Text(
                            item['source'] ?? 'AgriMart News',
                            style: GoogleFonts.inter(fontSize: r.sp(11), fontWeight: FontWeight.w700, color: AppColors.farmerAccent),
                          ),
                        ),
                        const Spacer(),
                        Text(_timeAgo(item['publishedAt']), style: GoogleFonts.inter(fontSize: r.sp(12), color: AppColors.muted)),
                      ],
                    ),
                    SizedBox(height: r.rs(16)),
                    Text(
                      item['title'] ?? '',
                      style: GoogleFonts.spaceGrotesk(fontSize: r.sp(22), fontWeight: FontWeight.w800, color: AppColors.ink, height: 1.2),
                    ),
                    SizedBox(height: r.rs(16)),
                    Text(
                      item['content'] ?? '',
                      style: GoogleFonts.inter(fontSize: r.sp(15), color: AppColors.ink.withValues(alpha: 0.85), height: 1.6),
                    ),
                    SizedBox(height: r.rs(40)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final isExternal = item['isExternal'] == true || (item['link'] != null && item['link'].toString().isNotEmpty);
    final sourceLabel = isExternal ? (item['source'] ?? 'External News') : (item['source'] ?? 'AgriMart');

    return GestureDetector(
      onTap: () => _openDetails(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(r.rs(20)),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
          boxShadow: AppColors.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item['imageUrl'] != null && item['imageUrl'].toString().isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(r.rs(20))),
                child: CachedNetworkImage(
                  imageUrl: item['imageUrl'],
                  height: r.rs(160),
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => ShimmerBox(height: r.rs(160), radius: 0),
                  errorWidget: (_, __, ___) => const SizedBox(),
                ),
              ),
            Padding(
              padding: EdgeInsets.all(r.rs(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (isLocal)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: r.rs(8), vertical: r.rs(4)),
                          decoration: BoxDecoration(
                            color: AppColors.farmerAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(r.rs(6)),
                            border: Border.all(color: AppColors.farmerAccent.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.location_on, size: r.rs(12), color: AppColors.farmerAccent),
                              SizedBox(width: r.rs(4)),
                              Text('Local News', style: GoogleFonts.inter(fontSize: r.sp(10), fontWeight: FontWeight.w700, color: AppColors.farmerAccent)),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: r.rs(8), vertical: r.rs(4)),
                          decoration: BoxDecoration(
                            color: AppColors.border.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(r.rs(6)),
                          ),
                          child: Text(sourceLabel, style: GoogleFonts.inter(fontSize: r.sp(10), fontWeight: FontWeight.w700, color: AppColors.ink)),
                        ),
                      Text(_timeAgo(item['publishedAt']), style: GoogleFonts.inter(fontSize: r.sp(11), color: AppColors.muted)),
                    ],
                  ),
                  SizedBox(height: r.rs(12)),
                  Text(item['title'] ?? '', style: GoogleFonts.spaceGrotesk(fontSize: r.sp(16), fontWeight: FontWeight.w700, color: AppColors.ink, height: 1.25)),
                  SizedBox(height: r.rs(8)),
                  Text(
                    item['content'] ?? '',
                    style: GoogleFonts.inter(fontSize: r.sp(13), color: AppColors.muted, height: 1.5),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: r.rs(16)),
                  Row(
                    children: [
                      Text('Read full story', style: GoogleFonts.inter(fontSize: r.sp(13), fontWeight: FontWeight.w700, color: AppColors.farmerAccent)),
                      SizedBox(width: r.rs(4)),
                      Icon(isExternal ? Icons.open_in_new : Icons.arrow_forward_rounded, size: r.rs(14), color: AppColors.farmerAccent),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
