import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agrimart/l10n/app_localizations.dart';
import '../../core/constants/farm_tools.dart';
import '../../core/providers/farm_tools_prefs_provider.dart';
import '../../core/utils/farm_tool_l10n.dart';
import '../../core/utils/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/agri_ui.dart';
import '../../core/widgets/offline_banner.dart';

class FarmToolsScreen extends ConsumerStatefulWidget {
  final bool embedded;
  const FarmToolsScreen({super.key, this.embedded = false});

  @override
  ConsumerState<FarmToolsScreen> createState() => _FarmToolsScreenState();
}

class _FarmToolsScreenState extends ConsumerState<FarmToolsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<FarmToolItem> _filterTools(List<FarmToolItem> tools) {
    if (_query.trim().isEmpty) return tools;
    final q = _query.toLowerCase();
    final l10n = AppLocalizations.of(context)!;
    return tools.where((t) {
      final label = farmToolLabelL10n(l10n, t).toLowerCase();
      return label.contains(q) || t.subtitle.toLowerCase().contains(q) || t.category.toLowerCase().contains(q);
    }).toList();
  }

  void _openTool(FarmToolItem tool) {
    ref.read(farmToolsPrefsProvider.notifier).markRecent(tool.route);
    context.push(tool.route);
  }

  Widget _content(BuildContext context) {
    final r = context.r;
    final l10n = AppLocalizations.of(context)!;
    final prefs = ref.watch(farmToolsPrefsProvider);
    final favorites = kFarmTools.where((t) => prefs.favorites.contains(t.route)).toList();
    final recent = prefs.recent
        .map((route) => kFarmTools.where((t) => t.route == route).firstOrNull)
        .whereType<FarmToolItem>()
        .toList();

    String labelFor(FarmToolItem t) => farmToolLabelL10n(l10n, t);
    String subtitleFor(FarmToolItem t) => farmToolSubtitleL10n(l10n, t);

    Widget toolGrid(List<FarmToolItem> tools, {bool compact = false}) {
      final filtered = _filterTools(tools);
      if (filtered.isEmpty && _query.isNotEmpty) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: r.rs(24)),
          child: Center(child: Text(l10n.noToolsMatch, style: GoogleFonts.inter(color: AppColors.muted))),
        );
      }
      return FarmToolsGrid(
        tools: filtered,
        compact: compact,
        labelFor: labelFor,
        subtitleFor: subtitleFor,
        onToolTap: _openTool,
      );
    }

    Widget favoriteChip(FarmToolItem tool) {
      final isFav = prefs.favorites.contains(tool.route);
      return Stack(
        clipBehavior: Clip.none,
        children: [
          FarmToolTile(
            tool: tool,
            compact: true,
            displayLabel: labelFor(tool),
            displaySubtitle: subtitleFor(tool),
            onTap: () => _openTool(tool),
          ),
          Positioned(
            right: 4,
            top: 4,
            child: GestureDetector(
              onTap: () => ref.read(farmToolsPrefsProvider.notifier).toggleFavorite(tool.route),
              child: Icon(
                isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                size: r.sp(18),
                color: isFav ? AppColors.warning : AppColors.muted,
              ),
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(r.horizontalPadding, widget.embedded ? r.rs(8) : r.rs(20), r.horizontalPadding, r.rs(32)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.embedded) ...[
            Text(l10n.farmToolkit, style: GoogleFonts.spaceGrotesk(fontSize: r.sp(22), fontWeight: FontWeight.w800, color: AppColors.ink)),
            SizedBox(height: r.rs(4)),
            Text(l10n.farmToolkitSubtitle, style: GoogleFonts.inter(fontSize: r.sp(13), color: AppColors.muted)),
            SizedBox(height: r.rs(16)),
          ],
          const OfflineBanner(),
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: l10n.searchTools,
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.muted),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(r.rs(14)), borderSide: BorderSide.none),
              contentPadding: EdgeInsets.symmetric(horizontal: r.rs(14), vertical: r.rs(12)),
            ),
          ),
          SizedBox(height: r.rs(16)),
          InfoBanner(text: l10n.farmToolkitBanner, icon: Icons.touch_app_rounded),
          if (favorites.isNotEmpty) ...[
            SizedBox(height: r.rs(24)),
            Text(l10n.favoriteTools, style: GoogleFonts.spaceGrotesk(fontSize: r.sp(17), fontWeight: FontWeight.w700, color: AppColors.ink)),
            SizedBox(height: r.rs(12)),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: r.toolGridColumns(),
                mainAxisSpacing: r.rs(10),
                crossAxisSpacing: r.rs(10),
                childAspectRatio: r.isTablet ? 0.9 : 0.82,
              ),
              itemCount: favorites.length,
              itemBuilder: (_, i) => favoriteChip(favorites[i]),
            ),
          ],
          if (recent.isNotEmpty && _query.isEmpty) ...[
            SizedBox(height: r.rs(24)),
            Text(l10n.recentTools, style: GoogleFonts.spaceGrotesk(fontSize: r.sp(17), fontWeight: FontWeight.w700, color: AppColors.ink)),
            SizedBox(height: r.rs(12)),
            toolGrid(recent, compact: true),
          ],
          SizedBox(height: r.rs(24)),
          ...kFarmToolCategories.map((cat) {
            final tools = farmToolsByCategory(cat);
            if (tools.isEmpty) return const SizedBox.shrink();
            final filtered = _filterTools(tools);
            if (filtered.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.only(bottom: r.rs(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: r.rs(4),
                        height: r.rh(18),
                        decoration: BoxDecoration(color: AppColors.farmerAccent, borderRadius: BorderRadius.circular(r.rs(2))),
                      ),
                      SizedBox(width: r.rs(10)),
                      Text(
                        farmToolCategoryL10n(l10n, cat),
                        style: GoogleFonts.spaceGrotesk(fontSize: r.sp(17), fontWeight: FontWeight.w700, color: AppColors.ink),
                      ),
                    ],
                  ),
                  SizedBox(height: r.rs(12)),
                  FarmToolsGrid(
                    tools: filtered,
                    labelFor: labelFor,
                    subtitleFor: subtitleFor,
                    onToolTap: _openTool,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final l10n = AppLocalizations.of(context)!;
    if (widget.embedded) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: context.r.bottomNavInset),
            child: ResponsiveLayout(applyPadding: false, child: _content(context)),
          ),
        ),
      );
    }
    return AgriScreen(
      title: l10n.farmToolkit,
      subtitle: l10n.farmToolkitSubtitle,
      emoji: '🧰',
      showBack: true,
      body: _content(context),
    );
  }
}
