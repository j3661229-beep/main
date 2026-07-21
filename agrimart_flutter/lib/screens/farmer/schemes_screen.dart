import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:animate_do/animate_do.dart';
import '../../data/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_fallback.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../core/utils/responsive.dart';

// ── Scheme category config ─────────────────────────────────────────────────────
const List<Map<String, dynamic>> _kCategories = [
  {'label': 'All',         'emoji': '📋', 'key': null},
  {'label': 'Subsidy',     'emoji': '💰', 'key': 'subsidy'},
  {'label': 'Insurance',   'emoji': '🛡️', 'key': 'insurance'},
  {'label': 'Loan',        'emoji': '🏦', 'key': 'loan'},
  {'label': 'Training',    'emoji': '📚', 'key': 'training'},
  {'label': 'Equipment',   'emoji': '🚜', 'key': 'equipment'},
];

// ── Color per scheme type ──────────────────────────────────────────────────────
Color _typeColor(String? type) {
  switch (type?.toLowerCase()) {
    case 'subsidy':   return const Color(0xFF2E7D52);
    case 'insurance': return const Color(0xFF1565C0);
    case 'loan':      return const Color(0xFF6A1B9A);
    case 'training':  return const Color(0xFFF57F17);
    case 'equipment': return const Color(0xFF5D4037);
    default:          return const Color(0xFF1A4E63);
  }
}

String _typeEmoji(String? type) {
  switch (type?.toLowerCase()) {
    case 'subsidy':   return '💰';
    case 'insurance': return '🛡️';
    case 'loan':      return '🏦';
    case 'training':  return '📚';
    case 'equipment': return '🚜';
    default:          return '🏛️';
  }
}

class SchemesScreen extends ConsumerStatefulWidget {
  const SchemesScreen({super.key});

  @override
  ConsumerState<SchemesScreen> createState() => _SchemesScreenState();
}

class _SchemesScreenState extends ConsumerState<SchemesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  int _selectedCategory = 0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (_, innerScrolled) => [
          // ── Hero AppBar ────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: r.rs(188),
            pinned: true,
            backgroundColor: const Color(0xFF0D2340),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _SchemesHeader(r: r),
            ),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(r.rh(46)),
              child: _StyledTabBar(ctrl: _tabCtrl),
            ),
          ),

          // ── Category Filter ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.background,
              padding: EdgeInsets.only(
                  top: r.rs(14), bottom: r.rs(4)),
              child: SizedBox(
                height: r.rs(38),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(
                      horizontal: r.horizontalPadding),
                  itemCount: _kCategories.length,
                  separatorBuilder: (_, __) => SizedBox(width: r.rs(8)),
                  itemBuilder: (_, i) {
                    final cat = _kCategories[i];
                    final isSel = _selectedCategory == i;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedCategory = i);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: EdgeInsets.symmetric(
                            horizontal: r.rs(12), vertical: r.rs(6)),
                        decoration: BoxDecoration(
                          color: isSel
                              ? const Color(0xFF0D2340)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(r.rs(20)),
                          border: Border.all(
                            color: isSel
                                ? const Color(0xFF0D2340)
                                : AppColors.border,
                          ),
                          boxShadow: isSel ? [
                            BoxShadow(
                              color: const Color(0xFF0D2340).withValues(alpha: 0.25),
                              blurRadius: r.rs(8),
                              offset: const Offset(0, 3),
                            )
                          ] : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(cat['emoji'] as String,
                                style: TextStyle(fontSize: r.sp(13))),
                            SizedBox(width: r.rs(5)),
                            Text(
                              cat['label'] as String,
                              style: GoogleFonts.inter(
                                fontSize: r.sp(12.5),
                                fontWeight: isSel
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color:
                                    isSel ? Colors.white : AppColors.ink,
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
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _SchemeList(
              provider: eligibleSchemesProvider,
              emptyTitle: 'No matched schemes',
              emptySubtitle:
                  'Complete your farm profile for personalised matches',
              filterKey: _kCategories[_selectedCategory]['key'] as String?,
              isForYou: true,
            ),
            _SchemeList(
              provider: schemesProvider,
              emptyTitle: 'No Schemes Found',
              emptySubtitle:
                  'Check back later for new government programs',
              filterKey: _kCategories[_selectedCategory]['key'] as String?,
              isForYou: false,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────────
class _SchemesHeader extends StatelessWidget {
  final Responsive r;
  const _SchemesHeader({required this.r});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF071525), Color(0xFF0D2340), Color(0xFF1A3A6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Decorative elements
          Positioned(
            right: -50, top: -40,
            child: Container(
              width: r.rs(220), height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),
          Positioned(
            left: -30, bottom: -50,
            child: Container(
              width: r.rs(160), height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4A90D9).withValues(alpha: 0.07),
              ),
            ),
          ),
          // Indian flag color strip at top
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: r.rh(3),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFFF9933), Color(0xFFFFFFFF),
                    Color(0xFF138808),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(
              r.horizontalPadding,
              r.safePadding.top + r.rs(50),
              r.horizontalPadding,
              r.rs(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: r.rs(46), height: r.rs(46),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(r.rs(13)),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Center(
                          child: Text('🏛️',
                              style: TextStyle(fontSize: r.sp(22)))),
                    ),
                    SizedBox(width: r.rs(14)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Govt Schemes',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: r.sp(24),
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              )),
                          Text(
                            'सरकारी योजनाएं • Subsidies, Loans & Insurance',
                            style: GoogleFonts.inter(
                                fontSize: r.sp(11), color: Colors.white60),
                          ),
                        ],
                      ),
                    ),
                    // Live badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: r.rs(9), vertical: r.rh(4)),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(r.rs(8)),
                        border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: r.rs(5), height: 5,
                            decoration: const BoxDecoration(
                                color: Color(0xFF90EE90),
                                shape: BoxShape.circle),
                          ),
                          SizedBox(width: r.rs(5)),
                          Text('LIVE',
                              style: GoogleFonts.inter(
                                  fontSize: r.sp(9),
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF90EE90))),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: r.rs(14)),
                // Stats row
                Row(
                  children: [
                    _StatPill(emoji: '📋', value: '50+', label: 'Schemes'),
                    SizedBox(width: r.rs(8)),
                    _StatPill(emoji: '💰', value: '₹2L+', label: 'Max Benefit'),
                    SizedBox(width: r.rs(8)),
                    _StatPill(emoji: '🆓', value: 'Free', label: 'Application'),
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

class _StatPill extends StatelessWidget {
  final String emoji, value, label;
  const _StatPill({required this.emoji, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: r.rs(10), vertical: r.rh(5)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(r.rs(20)),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: TextStyle(fontSize: r.sp(12))),
          SizedBox(width: r.rs(5)),
          Text(value,
              style: GoogleFonts.spaceGrotesk(
                  fontSize: r.sp(11),
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          SizedBox(width: r.rs(3)),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: r.sp(9), color: Colors.white60)),
        ],
      ),
    );
  }
}

// ── Styled Tab Bar ─────────────────────────────────────────────────────────────
class _StyledTabBar extends StatelessWidget {
  final TabController ctrl;
  const _StyledTabBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Container(
      color: const Color(0xFF0D2340),
      child: TabBar(
        controller: ctrl,
        indicatorColor: const Color(0xFF4A90D9),
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700, fontSize: r.sp(13.5)),
        unselectedLabelStyle:
            GoogleFonts.inter(fontSize: r.sp(13), fontWeight: FontWeight.w500),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        tabs: const [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('⭐ '),
                Text('For You'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('📋 '),
                Text('All Schemes'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Scheme List ────────────────────────────────────────────────────────────────
class _SchemeList extends ConsumerWidget {
  final FutureProvider<List> provider;
  final String emptyTitle;
  final String emptySubtitle;
  final String? filterKey;
  final bool isForYou;

  const _SchemeList({
    required this.provider,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.filterKey,
    required this.isForYou,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.r;
    final schemes = ref.watch(provider);

    return schemes.when(
      loading: () => _SchemesShimmer(),
      error: (e, _) => AppErrorState(
        message: 'Could not load schemes',
        onRetry: () => ref.invalidate(provider),
      ),
      data: (list) {
        final filtered = filterKey == null
            ? list
            : list
                .where((s) =>
                    (s as Map)['type']
                            ?.toString()
                            .toLowerCase() ==
                        filterKey)
                .toList();

        if (filtered.isEmpty) {
          return EmptyState(
            emoji: '🏛️',
            title: emptyTitle,
            subtitle: emptySubtitle,
          );
        }

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(
              r.horizontalPadding, r.rs(16),
              r.horizontalPadding, r.rs(36)),
          itemCount: filtered.length + (isForYou ? 1 : 0),
          itemBuilder: (ctx, i) {
            // "For You" tip banner at top
            if (isForYou && i == 0) {
              return Padding(
                padding: EdgeInsets.only(bottom: r.rs(16)),
                child: _ForYouBanner(count: filtered.length),
              );
            }
            final idx = isForYou ? i - 1 : i;
            return FadeInUp(
              delay: Duration(milliseconds: idx * 50),
              duration: const Duration(milliseconds: 300),
              child: Padding(
                padding: EdgeInsets.only(
                    bottom: idx < filtered.length - 1 ? r.rs(14) : 0),
                child: _SchemeCard(scheme: filtered[idx] as Map),
              ),
            );
          },
        );
      },
    );
  }
}

// ── For You Banner ─────────────────────────────────────────────────────────────
class _ForYouBanner extends StatelessWidget {
  final int count;
  const _ForYouBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Container(
      padding: EdgeInsets.all(r.rs(14)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D2340), Color(0xFF1A3A6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(r.rs(16)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D2340).withValues(alpha: 0.3),
            blurRadius: r.rs(14),
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Text('⭐', style: TextStyle(fontSize: r.sp(26))),
          SizedBox(width: r.rs(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$count schemes matched for you',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: r.sp(14),
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    )),
                SizedBox(height: r.rs(2)),
                Text('Based on your farm profile & location',
                    style: GoogleFonts.inter(
                        fontSize: r.sp(11.5), color: Colors.white60)),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: r.rs(10), vertical: r.rs(5)),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(r.rs(10)),
            ),
            child: Text('$count',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: r.sp(16),
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Scheme Card ────────────────────────────────────────────────────────────────
class _SchemeCard extends StatefulWidget {
  final Map scheme;
  const _SchemeCard({required this.scheme});

  @override
  State<_SchemeCard> createState() => _SchemeCardState();
}

class _SchemeCardState extends State<_SchemeCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _expandCtrl;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _expandCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 240));
    _expandAnim = CurvedAnimation(
        parent: _expandCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _expandCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.lightImpact();
    setState(() => _expanded = !_expanded);
    _expanded ? _expandCtrl.forward() : _expandCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final s = widget.scheme;
    final type = s['type']?.toString();
    final typeColor = _typeColor(type);
    final typeEmoji = _typeEmoji(type);
    final matchScore = s['matchScore'];
    final hasApplyUrl = s['applyUrl'] != null && s['applyUrl'].toString().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(r.rs(20)),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card Header ──────────────────────────────────────────────────
          GestureDetector(
            onTap: _toggle,
            child: Container(
              padding: EdgeInsets.all(r.rs(16)),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(r.rs(20))),
                border: Border(
                  bottom: BorderSide(
                      color: typeColor.withValues(alpha: 0.12)),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon container
                  Container(
                    width: r.rs(48), height: r.rs(48),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(r.rs(14)),
                      border: Border.all(
                          color: typeColor.withValues(alpha: 0.25)),
                    ),
                    child: Center(
                      child: Text(typeEmoji,
                          style: TextStyle(fontSize: r.sp(22))),
                    ),
                  ),
                  SizedBox(width: r.rs(12)),

                  // Title & ministry
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s['title']?.toString() ?? 'Scheme',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: r.sp(14.5),
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                            height: r.rh(1.25),
                          ),
                        ),
                        SizedBox(height: r.rs(4)),
                        Row(
                          children: [
                            Icon(Icons.account_balance_rounded,
                                size: r.sp(11), color: AppColors.muted),
                            SizedBox(width: r.rs(3)),
                            Expanded(
                              child: Text(
                                s['ministry']?.toString() ?? 'Govt of India',
                                style: GoogleFonts.inter(
                                    fontSize: r.sp(11),
                                    color: AppColors.muted,
                                    fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: r.rs(6)),
                        Row(
                          children: [
                            // Type chip
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: r.rs(8), vertical: r.rs(3)),
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(r.rs(8)),
                              ),
                              child: Text(
                                (type ?? 'Scheme').toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: r.sp(9.5),
                                  fontWeight: FontWeight.w800,
                                  color: typeColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            // Match score badge
                            if (matchScore != null) ...[
                              SizedBox(width: r.rs(6)),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: r.rs(8), vertical: r.rs(3)),
                                decoration: BoxDecoration(
                                  color: AppColors.successTint,
                                  borderRadius:
                                      BorderRadius.circular(r.rs(8)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star_rounded,
                                        color: AppColors.success, size: r.sp(10)),
                                    SizedBox(width: r.rs(3)),
                                    Text('$matchScore% match',
                                        style: GoogleFonts.inter(
                                          fontSize: r.sp(9.5),
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.success,
                                        )),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Expand chevron
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.muted,
                      size: r.rs(22),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Quick Benefit Preview (always visible) ───────────────────────
          if (s['benefits'] != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                  r.rs(16), r.rs(12), r.rs(16), r.rs(0)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: r.rs(28), height: r.rs(28),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(r.rs(8)),
                    ),
                    child: Center(child: Text('💡', style: TextStyle(fontSize: r.sp(14)))),
                  ),
                  SizedBox(width: r.rs(10)),
                  Expanded(
                    child: Text(
                      s['benefits'].toString(),
                      style: GoogleFonts.inter(
                        fontSize: r.sp(12.5),
                        color: AppColors.ink,
                        height: r.rh(1.4),
                      ),
                      maxLines: _expanded ? 100 : 2,
                      overflow: _expanded
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // ── Expandable Details ───────────────────────────────────────────
          SizeTransition(
            sizeFactor: _expandAnim,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  r.rs(16), r.rs(14), r.rs(16), r.rs(0)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (s['eligibility'] != null) ...[
                    _DetailSection(
                      icon: Icons.checklist_rounded,
                      title: 'Eligibility',
                      content: s['eligibility'].toString(),
                      color: const Color(0xFF1565C0),
                    ),
                    SizedBox(height: r.rs(12)),
                  ],
                  if (s['documents'] != null) ...[
                    _DetailSection(
                      icon: Icons.folder_outlined,
                      title: 'Documents Required',
                      content: s['documents'].toString(),
                      color: const Color(0xFFF57F17),
                    ),
                    SizedBox(height: r.rs(12)),
                  ],
                  if (s['deadline'] != null) ...[
                    _DeadlineBanner(deadline: s['deadline'].toString()),
                    SizedBox(height: r.rs(12)),
                  ],
                ],
              ),
            ),
          ),

          // ── Footer ───────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.all(r.rs(14)),
            child: Row(
              children: [
                // More details button
                Expanded(
                  child: GestureDetector(
                    onTap: _toggle,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(vertical: r.rs(10)),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius:
                            BorderRadius.circular(r.rs(12)),
                        border:
                            Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _expanded
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            size: r.rs(16),
                            color: AppColors.muted,
                          ),
                          SizedBox(width: r.rs(4)),
                          Text(
                            _expanded ? 'Less' : 'Details',
                            style: GoogleFonts.inter(
                              fontSize: r.sp(12.5),
                              fontWeight: FontWeight.w600,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                if (hasApplyUrl) ...[
                  SizedBox(width: r.rs(10)),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () async {
                        HapticFeedback.mediumImpact();
                        final url = Uri.parse(s['applyUrl'].toString());
                        if (await canLaunchUrl(url)) {
                          await launchUrl(
                              url, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(vertical: r.rs(10)),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0D2340), Color(0xFF1A3A6A)],
                          ),
                          borderRadius:
                              BorderRadius.circular(r.rs(12)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0D2340)
                                  .withValues(alpha: 0.35),
                              blurRadius: r.rs(10),
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.open_in_new_rounded,
                                color: Colors.white, size: r.sp(15)),
                            SizedBox(width: r.rs(6)),
                            Text(
                              'Apply Online',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: r.sp(13),
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Detail Section ─────────────────────────────────────────────────────────────
class _DetailSection extends StatelessWidget {
  final IconData icon;
  final String title, content;
  final Color color;
  const _DetailSection({
    required this.icon,
    required this.title,
    required this.content,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Container(
      padding: EdgeInsets.all(r.rs(12)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(r.rs(12)),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: r.rs(14), color: color),
              SizedBox(width: r.rs(6)),
              Text(title,
                  style: GoogleFonts.inter(
                      fontSize: r.sp(11),
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: 0.3)),
            ],
          ),
          SizedBox(height: r.rs(7)),
          Text(content,
              style: GoogleFonts.inter(
                  fontSize: r.sp(12.5),
                  color: AppColors.ink,
                  height: 1.45)),
        ],
      ),
    );
  }
}

// ── Deadline Banner ────────────────────────────────────────────────────────────
class _DeadlineBanner extends StatelessWidget {
  final String deadline;
  const _DeadlineBanner({required this.deadline});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Container(
      padding: EdgeInsets.all(r.rs(10)),
      decoration: BoxDecoration(
        color: AppColors.warningTint,
        borderRadius: BorderRadius.circular(r.rs(10)),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text('⏰', style: TextStyle(fontSize: r.sp(14))),
          SizedBox(width: r.rs(8)),
          Expanded(
            child: Text(
              'Last date: $deadline',
              style: GoogleFonts.inter(
                  fontSize: r.sp(12),
                  fontWeight: FontWeight.w700,
                  color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shimmer ────────────────────────────────────────────────────────────────────
class _SchemesShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
          r.horizontalPadding, r.rs(16),
          r.horizontalPadding, r.rs(32)),
      itemCount: 5,
      separatorBuilder: (_, __) => SizedBox(height: r.rs(14)),
      itemBuilder: (_, __) => ShimmerBox(height: r.rs(160), radius: r.rs(20)),
    );
  }
}
