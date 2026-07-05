// shared/widgets — AppButton, RoleBadge, StatCard, ListRow, BadgeChip
// All widgets match the AgriMart design spec exactly.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../utils/responsive.dart';

// ── AppButton ─────────────────────────────────────────────
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isOutlined;
  final Color? color;
  final Color? textColor;
  final IconData? icon;
  final double? width;
  final double height;
  final double radius;

  const AppButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.isOutlined = false,
    this.color,
    this.textColor,
    this.icon,
    this.width,
    this.height = 52,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final bg = color ?? AppColors.farmerAccent;
    final fg = textColor ?? Colors.white;
    final btnHeight = height == 52 ? r.rs(52) : height;
    final btnRadius = radius == 14 ? r.rs(14) : radius;

    return SizedBox(
      width: width ?? double.infinity,
      height: btnHeight,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: (isLoading || onTap == null) ? null : onTap,
            borderRadius: BorderRadius.circular(btnRadius),
            child: Ink(
              decoration: BoxDecoration(
                color: isOutlined ? Colors.transparent : (onTap == null ? AppColors.border : bg),
                border: isOutlined ? Border.all(color: bg, width: 1.5) : null,
                borderRadius: BorderRadius.circular(btnRadius),
                boxShadow: isOutlined || onTap == null
                    ? null
                    : [BoxShadow(color: bg.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 6))],
              ),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(isOutlined ? bg : fg),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, color: isOutlined ? bg : fg, size: 18),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            label,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: r.sp(15),
                              fontWeight: FontWeight.w600,
                              color: isOutlined ? bg : fg,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── RoleBadge ─────────────────────────────────────────────
/// The dashed-circle "stamp" motif for role display
class RoleBadge extends StatelessWidget {
  final String role;
  final double size;
  final bool showLabel;

  const RoleBadge({super.key, required this.role, this.size = 80, this.showLabel = true});

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accentFor(role);
    final tint   = AppColors.tintFor(role);
    final emoji  = _emoji();
    final label  = _label();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size(size, size),
          painter: _DashedCirclePainter(color: accent),
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tint,
              shape: BoxShape.circle,
            ),
            child: Text(emoji, style: TextStyle(fontSize: size * 0.4)),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: accent,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ],
    );
  }

  String _emoji() {
    switch (role.toUpperCase()) {
      case 'SUPPLIER': return '🏪';
      case 'DEALER':   return '🤝';
      default:         return '🌾';
    }
  }

  String _label() {
    switch (role.toUpperCase()) {
      case 'SUPPLIER': return 'SUPPLIER';
      case 'DEALER':   return 'DEALER';
      default:         return 'FARMER';
    }
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    const dashCount = 20;
    const dashAngle = 2 * 3.14159265 / dashCount;
    final r = size.width / 2 - 3;
    final center = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i < dashCount; i++) {
      final start = (i * dashAngle) - 3.14159265 / 2;
      final end   = start + dashAngle * 0.55;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        start, end - start, false, paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) => old.color != color;
}

// ── StatCard ──────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final Color tint;
  final String? subtitle;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.accent = AppColors.farmerAccent,
    this.tint   = AppColors.farmerTint,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Container(
      padding: EdgeInsets.all(r.rs(16)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(r.rs(16)),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: r.rs(36), height: r.rs(36),
            decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(r.rs(10))),
            child: Icon(icon, color: accent, size: r.rs(20)),
          ),
          SizedBox(height: r.rs(12)),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(fontSize: r.sp(22), fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
          SizedBox(height: r.rs(2)),
          Text(label, style: GoogleFonts.inter(fontSize: r.sp(12), color: AppColors.muted)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: GoogleFonts.inter(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w500)),
          ],
        ],
      ),
    );
  }
}

// ── ListRow ───────────────────────────────────────────────
class ListRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? trailing;
  final Widget? trailingWidget;
  final Widget? leadingWidget;
  final IconData? leadingIcon;
  final Color? leadingColor;
  final VoidCallback? onTap;
  final bool showDivider;

  const ListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.trailingWidget,
    this.leadingWidget,
    this.leadingIcon,
    this.leadingColor,
    this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              if (leadingWidget != null)
                leadingWidget!
              else if (leadingIcon != null)
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: (leadingColor ?? AppColors.farmerAccent).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(leadingIcon, color: leadingColor ?? AppColors.farmerAccent, size: 20),
                ),
              if (leadingWidget != null || leadingIcon != null) const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
                    ],
                  ],
                ),
              ),
              if (trailingWidget != null)
                trailingWidget!
              else if (trailing != null)
                Text(trailing!, style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w500))
              else if (onTap != null)
                const Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── BadgeChip ─────────────────────────────────────────────
class BadgeChip extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? textColor;
  final bool outlined;

  const BadgeChip({
    super.key,
    required this.label,
    this.color,
    this.textColor,
    this.outlined = false,
  });

  factory BadgeChip.status(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return BadgeChip(label: status, color: AppColors.warningTint, textColor: AppColors.warning);
      case 'CONFIRMED':
      case 'SHIPPED':
        return BadgeChip(label: status, color: AppColors.infoTint, textColor: AppColors.info);
      case 'DELIVERED':
      case 'COMPLETED':
        return BadgeChip(label: status, color: AppColors.successTint, textColor: AppColors.success);
      case 'CANCELLED':
      case 'FAILED':
        return BadgeChip(label: status, color: AppColors.dangerTint, textColor: AppColors.danger);
      case 'AWAITING REPLY':
        return BadgeChip(label: status, color: AppColors.warningTint, textColor: AppColors.warning);
      default:
        return BadgeChip(label: status, color: AppColors.border, textColor: AppColors.muted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = outlined ? Colors.transparent : (color ?? AppColors.farmerTint);
    final fg = textColor ?? AppColors.farmerAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        border: outlined ? Border.all(color: fg, width: 1.2) : Border.all(color: (color ?? AppColors.farmerTint).withValues(alpha: 0.8)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: fg, letterSpacing: 0.3),
      ),
    );
  }
}

// ── FilterChip Row ────────────────────────────────────────
class FilterChipRow extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final void Function(String) onSelect;
  final Color accent;

  const FilterChipRow({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelect,
    this.accent = AppColors.farmerAccent,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: r.horizontalPadding),
      child: Row(
        children: options.map((opt) {
          final isSelected = opt == selected;
          return Padding(
            padding: EdgeInsets.only(right: r.rs(8)),
            child: GestureDetector(
              onTap: () => onSelect(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: r.rs(16), vertical: r.rs(8)),
                decoration: BoxDecoration(
                  color: isSelected ? accent : AppColors.surface,
                  border: Border.all(color: isSelected ? accent : AppColors.border),
                  borderRadius: BorderRadius.circular(r.rs(20)),
                ),
                child: Text(
                  opt,
                  style: GoogleFonts.inter(
                    fontSize: r.sp(13),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? Colors.white : AppColors.ink,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── LoadingShimmer ────────────────────────────────────────
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  const ShimmerBox({super.key, this.width = double.infinity, required this.height, this.radius = 12});

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
    _anim = Tween<double>(begin: -2, end: 2).animate(CurvedAnimation(parent: _ctrl, curve: Curves.linear));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            colors: const [Color(0xFFEDE8DA), Color(0xFFF6F1E4), Color(0xFFEDE8DA)],
            stops: const [0.0, 0.5, 1.0],
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value + 1, 0),
          ),
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(r.rs(40)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: TextStyle(fontSize: r.sp(56))),
            SizedBox(height: r.rs(16)),
            Text(title, style: GoogleFonts.spaceGrotesk(fontSize: r.sp(20), fontWeight: FontWeight.w700, color: AppColors.ink), textAlign: TextAlign.center),
            SizedBox(height: r.rs(8)),
            Text(subtitle, style: GoogleFonts.inter(fontSize: r.sp(14), color: AppColors.muted), textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: r.rs(24)),
              AppButton(label: actionLabel!, onTap: onAction, width: r.rs(180), height: r.rs(46)),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Padding(
      padding: EdgeInsets.fromLTRB(r.horizontalPadding, r.rs(20), r.horizontalPadding, r.rs(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.spaceGrotesk(fontSize: r.sp(16), fontWeight: FontWeight.w700, color: AppColors.ink)),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Text(actionLabel!, style: GoogleFonts.inter(fontSize: r.sp(13), fontWeight: FontWeight.w500, color: AppColors.farmerAccent)),
            ),
        ],
      ),
    );
  }
}

// ── Indian Rupee formatter ────────────────────────────────
String formatRupee(num amount) {
  final str = amount.toStringAsFixed(0);
  if (str.length <= 3) return '₹$str';
  final last3 = str.substring(str.length - 3);
  final rest = str.substring(0, str.length - 3);
  final buf = StringBuffer();
  for (int i = 0; i < rest.length; i++) {
    if (i > 0 && (rest.length - i) % 2 == 0) buf.write(',');
    buf.write(rest[i]);
  }
  return '₹$buf,$last3';
}

