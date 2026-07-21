import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../core/providers/app_language_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../data/providers/youtube_provider.dart';
import 'video_player_screen.dart';

class KrishiTvScreen extends ConsumerStatefulWidget {
  const KrishiTvScreen({super.key});

  @override
  ConsumerState<KrishiTvScreen> createState() => _KrishiTvScreenState();
}

class _KrishiTvScreenState extends ConsumerState<KrishiTvScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  int _selectedCategory = 0;
  bool _searchActive = false;   // search bar is focused/active
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() {
      setState(() => _searchActive = _searchFocus.hasFocus || _searchCtrl.text.isNotEmpty);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (mounted) {
        ref.read(youtubeSearchQueryProvider.notifier).state = q.trim();
      }
    });
    setState(() {}); // rebuild to show/hide clear button
  }

  void _clearSearch() {
    _searchCtrl.clear();
    _searchFocus.unfocus();
    ref.read(youtubeSearchQueryProvider.notifier).state = '';
    setState(() => _searchActive = false);
  }

  void _openVideo(Map<String, dynamic> video) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(
          videoId: video['videoId']?.toString() ?? '',
          title: video['title']?.toString() ?? 'Farming Video',
          channel: video['channel']?.toString() ?? 'AgriChannel',
          thumbnailUrl: video['thumbnail']?.toString(),
        ),
      ),
    );
  }

  bool get _isSearching =>
      ref.watch(youtubeSearchQueryProvider).isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final lang = ref.watch(appLanguageProvider);
    final ytCtx = ref.watch(youtubeLocaleProvider);
    final categories = farmingCategoriesFor(lang);
    final suggestions = popularSearchSuggestionsFor(lang);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: r.rs(158),
            pinned: true,
            backgroundColor: const Color(0xFF12121E),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: r.sp(24)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _KrishiHeader(
                district: ytCtx.district,
                languageLabel: lang.aiName,
              ),
            ),
          ),

          // ── Search Bar (always visible below header) ─────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: const Color(0xFF12121E),
              padding: EdgeInsets.fromLTRB(
                  r.horizontalPadding, 0, r.horizontalPadding, r.rs(12)),
              child: _SearchBar(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                onChanged: _onSearchChanged,
                onClear: _clearSearch,
                hint: _searchHint(ref.read(localeProvider).languageCode),
              ),
            ),
          ),

          // ── Category chips (hidden during search) ────────────────────────
          if (!_isSearching)
            SliverToBoxAdapter(
              child: Container(
                color: const Color(0xFF12121E),
                padding: EdgeInsets.only(bottom: r.rs(12)),
                child: SizedBox(
                  height: r.rs(40),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(
                        horizontal: r.horizontalPadding),
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => SizedBox(width: r.rs(8)),
                    itemBuilder: (_, i) {
                      final cat = categories[i];
                      final isSel = _selectedCategory == i;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedCategory = i);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: EdgeInsets.symmetric(
                              horizontal: r.rs(14), vertical: r.rs(7)),
                          decoration: BoxDecoration(
                            color: isSel
                                ? Colors.red
                                : Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(r.rs(20)),
                            border: Border.all(
                              color: isSel
                                  ? Colors.red
                                  : Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(cat['emoji']!,
                                  style: TextStyle(fontSize: r.sp(13))),
                              SizedBox(width: r.rs(5)),
                              Text(
                                cat['label']!,
                                style: GoogleFonts.inter(
                                  fontSize: r.sp(12.5),
                                  fontWeight: isSel
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

          // ── Content ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                r.horizontalPadding, r.rs(18),
                r.horizontalPadding, r.bottomNavInset + r.rs(16),
              ),
              child: _isSearching
                  ? _SearchResults(
                      query: ref.watch(youtubeSearchQueryProvider),
                      onVideoTap: _openVideo,
                    )
                  : _searchActive && _searchCtrl.text.isEmpty
                      ? _SearchSuggestions(
                          suggestions: suggestions,
                          categories: categories,
                          onTap: (q) {
                          _searchCtrl.text = q;
                          _onSearchChanged(q);
                        })
                      : _BrowseContent(
                          selectedCategory: _selectedCategory,
                          categories: categories,
                          onVideoTap: _openVideo,
                        ),
            ),
          ),
        ],
      ),
    );
  }

  String _searchHint(String code) {
    if (code == 'mr') return 'शेती व्हिडिओ शोधा…';
    if (code == 'hi') return 'खेती वीडियो खोजें…';
    return 'Search farming videos…';
  }
}

// ── Krishi Header ─────────────────────────────────────────────────────────────
class _KrishiHeader extends StatelessWidget {
  final String district;
  final String languageLabel;

  const _KrishiHeader({required this.district, required this.languageLabel});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D0D1A), Color(0xFF1A1535), Color(0xFF0F2550)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Red glow circle
          Positioned(
            right: -50, top: -30,
            child: Container(
              width: r.rs(200), height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withValues(alpha: 0.07),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              r.horizontalPadding,
              r.safePadding.top + r.rs(52),
              r.horizontalPadding,
              r.rs(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Container(
                      width: r.rs(42), height: r.rs(42),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(r.rs(12)),
                        border: Border.all(
                            color: Colors.red.withValues(alpha: 0.4)),
                      ),
                      child: Icon(Icons.play_circle_filled_rounded,
                          color: Colors.red, size: r.sp(24)),
                    ),
                    SizedBox(width: r.rs(12)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Krishi TV',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: r.sp(24),
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            )),
                        Text('$languageLabel • $district',
                            style: GoogleFonts.inter(
                              fontSize: r.sp(11.5),
                              color: Colors.white60,
                            )),
                      ],
                    ),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: r.rs(8), vertical: r.rh(4)),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(r.rs(8)),
                        border: Border.all(
                            color: Colors.red.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: r.rs(6), height: 6,
                            decoration: const BoxDecoration(
                                color: Colors.red, shape: BoxShape.circle),
                          ),
                          SizedBox(width: r.rs(5)),
                          Text('LIVE',
                              style: GoogleFonts.inter(
                                fontSize: r.sp(10),
                                fontWeight: FontWeight.w800,
                                color: Colors.red,
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Search Bar ────────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final String hint;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Container(
      height: r.rh(48),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(r.rs(14)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          SizedBox(width: r.rs(14)),
          Icon(Icons.search_rounded, color: Colors.white54, size: r.sp(20)),
          SizedBox(width: r.rs(10)),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: GoogleFonts.inter(color: Colors.white, fontSize: r.sp(14)),
              cursorColor: Colors.red,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.inter(
                    color: Colors.white38, fontSize: r.sp(13.5)),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: Padding(
                padding: EdgeInsets.all(r.rs(12)),
                child: Icon(Icons.close_rounded,
                    color: Colors.white54, size: r.sp(18)),
              ),
            )
          else
            SizedBox(width: r.rs(14)),
        ],
      ),
    );
  }
}

// ── Search Suggestions (shown when search bar focused but empty) ──────────────
class _SearchSuggestions extends StatelessWidget {
  final void Function(String) onTap;
  final List<String> suggestions;
  final List<Map<String, String>> categories;

  const _SearchSuggestions({
    required this.onTap,
    required this.suggestions,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.local_fire_department_rounded,
                color: AppColors.warning, size: r.sp(18)),
            SizedBox(width: r.rs(8)),
            Text(
              'Popular Searches',
              style: GoogleFonts.spaceGrotesk(
                fontSize: r.sp(16),
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
        SizedBox(height: r.rs(16)),
        Wrap(
          spacing: r.rs(8),
          runSpacing: r.rs(8),
          children: suggestions.map((s) {
            return GestureDetector(
              onTap: () => onTap(s),
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: r.rs(14), vertical: r.rs(9)),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(r.rs(22)),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppColors.softShadow,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_rounded,
                        size: r.sp(14), color: AppColors.muted),
                    SizedBox(width: r.rs(6)),
                    Text(
                      s,
                      style: GoogleFonts.inter(
                        fontSize: r.sp(13),
                        fontWeight: FontWeight.w500,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: r.rs(28)),
        // Quick category tiles
        Text(
          'Browse by Topic',
          style: GoogleFonts.spaceGrotesk(
            fontSize: r.sp(16),
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        SizedBox(height: r.rs(12)),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: r.isTablet ? 4 : 3,
          mainAxisSpacing: r.rs(10),
          crossAxisSpacing: r.rs(10),
          childAspectRatio: 1.6,
          children: categories.skip(1).map((cat) {
            return GestureDetector(
              onTap: () => onTap(cat['query']!),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(r.rs(14)),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(cat['emoji']!,
                        style: TextStyle(fontSize: r.sp(22))),
                    SizedBox(height: r.rs(4)),
                    Text(
                      cat['label']!,
                      style: GoogleFonts.inter(
                        fontSize: r.sp(11),
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Browse Content ────────────────────────────────────────────────────────────
class _BrowseContent extends ConsumerWidget {
  final int selectedCategory;
  final List<Map<String, String>> categories;
  final void Function(Map<String, dynamic>) onVideoTap;

  const _BrowseContent({
    required this.selectedCategory,
    required this.categories,
    required this.onVideoTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.r;
    final category = categories[selectedCategory];
    final provider = selectedCategory == 0
        ? ref.watch(youtubeTrendingProvider)
        : ref.watch(youtubeCategoryProvider(category['query']!));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeInUp(
          duration: const Duration(milliseconds: 300),
          child: Row(
            children: [
              Text(category['emoji']!, style: TextStyle(fontSize: r.sp(22))),
              SizedBox(width: r.rs(8)),
              Text(
                selectedCategory == 0
                    ? 'Trending Farming Videos'
                    : '${category['label']} Videos',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: r.sp(18),
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: r.rs(4)),
        Text(
          'Tap any video to watch in-app',
          style: GoogleFonts.inter(
              fontSize: r.sp(12), color: AppColors.muted),
        ),
        SizedBox(height: r.rs(16)),
        provider.when(
          loading: () => _VideoGridShimmer(columns: r.isTablet ? 3 : 2),
          error: (_, __) => _ErrorCard(
              onRetry: () => ref.invalidate(youtubeTrendingProvider)),
          data: (videos) {
            if (videos.isEmpty) return const _EmptyVideoCard();
            return _VideoGrid(videos: videos, onTap: onVideoTap);
          },
        ),
      ],
    );
  }
}

// ── Search Results ────────────────────────────────────────────────────────────
class _SearchResults extends ConsumerWidget {
  final String query;
  final void Function(Map<String, dynamic>) onVideoTap;

  const _SearchResults({required this.query, required this.onVideoTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.r;
    final results = ref.watch(youtubeSearchProvider(query));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding:
                  EdgeInsets.symmetric(horizontal: r.rs(10), vertical: r.rh(5)),
              decoration: BoxDecoration(
                color: AppColors.farmerTint,
                borderRadius: BorderRadius.circular(r.rs(20)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_rounded,
                      size: r.sp(15), color: AppColors.farmerAccent),
                  SizedBox(width: r.rs(5)),
                  Text(
                    'Results for "$query"',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: r.sp(13),
                      fontWeight: FontWeight.w700,
                      color: AppColors.farmerAccent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: r.rs(16)),
        results.when(
          loading: () => _VideoGridShimmer(columns: r.isTablet ? 3 : 2),
          error: (_, __) => _ErrorCard(
              onRetry: () =>
                  ref.invalidate(youtubeSearchProvider(query))),
          data: (videos) {
            if (videos.isEmpty) {
              return _EmptySearchCard(query: query);
            }
            return _VideoGrid(videos: videos, onTap: onVideoTap);
          },
        ),
      ],
    );
  }
}

// ── Video Grid ────────────────────────────────────────────────────────────────
class _VideoGrid extends StatelessWidget {
  final List<Map<String, dynamic>> videos;
  final void Function(Map<String, dynamic>) onTap;

  const _VideoGrid({required this.videos, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: r.isTablet ? 3 : 2,
        crossAxisSpacing: r.rs(12),
        mainAxisSpacing: r.rs(14),
        childAspectRatio: 0.72,
      ),
      itemCount: videos.length,
      itemBuilder: (_, i) => FadeInUp(
        delay: Duration(milliseconds: i * 40),
        duration: const Duration(milliseconds: 280),
        child: _VideoCard(
          video: videos[i],
          onTap: () => onTap(videos[i]),
        ),
      ),
    );
  }
}

// ── Video Card ────────────────────────────────────────────────────────────────
class _VideoCard extends StatefulWidget {
  final Map<String, dynamic> video;
  final VoidCallback onTap;

  const _VideoCard({required this.video, required this.onTap});

  @override
  State<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<_VideoCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final thumb = widget.video['thumbnail']?.toString() ?? '';
    final videoId = widget.video['videoId']?.toString() ?? '';
    final thumbUrl = thumb.isNotEmpty
        ? thumb
        : 'https://img.youtube.com/vi/$videoId/mqdefault.jpg';
    final duration = widget.video['duration']?.toString() ?? '';

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(r.rs(16)),
            boxShadow: AppColors.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(r.rs(16))),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: thumbUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: const Color(0xFFEDE8DA),
                          child: Center(
                            child: Icon(Icons.play_circle_outline_rounded,
                                color: AppColors.farmerAccent,
                                size: r.rs(30)),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.farmerTint,
                          child: Center(
                            child: Text('🌾',
                                style: TextStyle(fontSize: r.sp(24))),
                          ),
                        ),
                      ),
                      // Dark gradient overlay
                      Positioned(
                        bottom: 0, left: 0, right: 0,
                        child: Container(
                          height: r.rh(40),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                      // Play button
                      Center(
                        child: Container(
                          width: r.rs(36), height: r.rs(36),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: Icon(Icons.play_arrow_rounded,
                              color: Colors.white, size: r.sp(22)),
                        ),
                      ),
                      // Duration badge
                      if (duration.isNotEmpty)
                        Positioned(
                          bottom: 5, right: 5,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: r.rs(5), vertical: r.rh(2)),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(r.rs(4)),
                            ),
                            child: Text(duration,
                                style: GoogleFonts.inter(
                                    fontSize: r.sp(9.5),
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                      // YT badge
                      Positioned(
                        top: 5, left: 5,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: r.rs(5), vertical: r.rh(2)),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(r.rs(4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.play_arrow_rounded,
                                  color: Colors.white, size: r.sp(9)),
                              Text(' YT',
                                  style: GoogleFonts.inter(
                                      fontSize: r.sp(8),
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Info section
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(r.rs(9)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.video['title']?.toString() ?? 'Farming Video',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: r.sp(11.5),
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                            height: r.rh(1.3),
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(height: r.rs(4)),
                      Row(
                        children: [
                          Icon(Icons.account_circle_rounded,
                              size: r.sp(12), color: AppColors.placeholder),
                          SizedBox(width: r.rs(4)),
                          Expanded(
                            child: Text(
                              widget.video['channel']?.toString() ?? '',
                              style: GoogleFonts.inter(
                                  fontSize: r.sp(10),
                                  color: AppColors.muted),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shimmer ───────────────────────────────────────────────────────────────────
class _VideoGridShimmer extends StatelessWidget {
  final int columns;
  const _VideoGridShimmer({required this.columns});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: r.rs(12),
        mainAxisSpacing: r.rs(14),
        childAspectRatio: 0.72,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: const Color(0xFFEDE8DA),
        highlightColor: const Color(0xFFF6F1E4),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(r.rs(16)),
          ),
        ),
      ),
    );
  }
}

// ── Error & Empty cards ───────────────────────────────────────────────────────
class _ErrorCard extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorCard({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Container(
      padding: EdgeInsets.all(r.rs(24)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(r.rs(18)),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: [
          Text('📡', style: TextStyle(fontSize: r.sp(40))),
          SizedBox(height: r.rh(12)),
          Text('Could not load videos',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: r.sp(16), fontWeight: FontWeight.w700)),
          SizedBox(height: r.rh(4)),
          Text('Check your internet connection',
              style: GoogleFonts.inter(
                  fontSize: r.sp(13), color: AppColors.muted)),
          SizedBox(height: r.rh(16)),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: r.rs(24), vertical: r.rh(10)),
              decoration: BoxDecoration(
                color: AppColors.farmerAccent,
                borderRadius: BorderRadius.circular(r.rs(20)),
              ),
              child: Text('Try Again',
                  style: GoogleFonts.inter(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyVideoCard extends StatelessWidget {
  const _EmptyVideoCard();

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Container(
      padding: EdgeInsets.all(r.rs(24)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(r.rs(18)),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: [
          Text('🎬', style: TextStyle(fontSize: r.sp(40))),
          SizedBox(height: r.rh(12)),
          Text('No videos available',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: r.sp(16), fontWeight: FontWeight.w700)),
          Text('Try a different category',
              style: GoogleFonts.inter(
                  fontSize: r.sp(13), color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _EmptySearchCard extends StatelessWidget {
  final String query;
  const _EmptySearchCard({required this.query});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Container(
      padding: EdgeInsets.all(r.rs(24)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(r.rs(18)),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: [
          Text('🔍', style: TextStyle(fontSize: r.sp(40))),
          SizedBox(height: r.rh(12)),
          Text('No results for "$query"',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: r.sp(15), fontWeight: FontWeight.w700)),
          SizedBox(height: r.rh(4)),
          Text('Try searching in Hindi or English',
              style: GoogleFonts.inter(
                  fontSize: r.sp(13), color: AppColors.muted)),
        ],
      ),
    );
  }
}
