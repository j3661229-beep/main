import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:agrimart/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';

/// Version 1 — Farmer-only landing. Supplier/Dealer hidden behind 5× tap easter egg.
class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});
  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  int _businessTapCount = 0;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _onBusinessTap() {
    _businessTapCount++;
    // Hidden: 5 taps reveals business login (for admin/supplier/dealer)
    if (_businessTapCount >= 5) {
      _businessTapCount = 0;
      _showBusinessSheet();
    }
  }

  void _showBusinessSheet() {
    final r = context.r;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.all(r.rs(24)),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(r.rs(2)))),
            SizedBox(height: r.rh(20)),
            Text('Business Login', style: GoogleFonts.spaceGrotesk(
              fontSize: r.sp(20), fontWeight: FontWeight.w800, color: AppColors.ink)),
            SizedBox(height: r.rh(6)),
            Text('For Suppliers & Dealers only', style: GoogleFonts.inter(
              fontSize: r.sp(13), color: AppColors.muted)),
            SizedBox(height: r.rh(24)),
            _BizRoleBtn(
              emoji: '🏪', label: 'Supplier Login',
              accent: AppColors.supplierAccent, tint: AppColors.supplierTint,
              onTap: () { Navigator.pop(context); context.push('/auth/login?role=SUPPLIER'); },
            ),
            SizedBox(height: r.rh(12)),
            _BizRoleBtn(
              emoji: '🤝', label: 'Dealer Login',
              accent: AppColors.dealerAccent, tint: AppColors.dealerTint,
              onTap: () { Navigator.pop(context); context.push('/auth/login?role=DEALER'); },
            ),
            SizedBox(height: r.rh(24)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background decorative circles
          Positioned(
            top: -80, right: -60,
            child: Container(
              width: r.rs(260), height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.farmerAccent.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -60, left: -80,
            child: Container(
              width: r.rs(300), height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.farmerAccent.withValues(alpha: 0.04),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: r.horizontalPadding),
              child: Column(
                children: [
                  SizedBox(height: r.rs(40)),

                  // ── App Logo + Name ───────────────────────────────────
                  FadeInDown(
                    duration: const Duration(milliseconds: 700),
                    child: Column(
                      children: [
                        ScaleTransition(
                          scale: _pulseAnim,
                          child: Container(
                            width: r.rs(88),
                            height: r.rs(88),
                            decoration: BoxDecoration(
                              gradient: AppColors.farmerGradient,
                              borderRadius: BorderRadius.circular(r.rs(24)),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.farmerAccent.withValues(alpha: 0.4),
                                  blurRadius: r.rs(24),
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text('🌱', style: TextStyle(fontSize: r.sp(44))),
                            ),
                          ),
                        ),
                        SizedBox(height: r.rs(18)),
                        Text(
                          'AgriMart',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: r.sp(36),
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: r.rs(6)),
                        Text(
                          l10n.indianAgriMarketplace,
                          style: GoogleFonts.inter(
                            fontSize: r.sp(14),
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: r.rs(48)),

                  // ── Hero Card ─────────────────────────────────────────
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    duration: const Duration(milliseconds: 600),
                    child: Container(
                      padding: EdgeInsets.all(r.rs(28)),
                      decoration: BoxDecoration(
                        gradient: AppColors.farmerGradient,
                        borderRadius: BorderRadius.circular(r.rs(28)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.farmerAccent.withValues(alpha: 0.35),
                            blurRadius: r.rs(28),
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(r.rs(10)),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(r.rs(14)),
                                ),
                                child: Text('🌾', style: TextStyle(fontSize: r.sp(28))),
                              ),
                              SizedBox(width: r.rs(14)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.farmerRole,
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: r.sp(22),
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      l10n.farmerRoleDesc,
                                      style: GoogleFonts.inter(
                                        fontSize: r.sp(12),
                                        color: Colors.white.withValues(alpha: 0.8),
                                        height: r.rh(1.4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: r.rs(24)),

                          // Feature pills
                          Wrap(
                            spacing: r.rs(8),
                            runSpacing: r.rs(8),
                            children: [
                              _FeaturePill(icon: '🤖', label: 'Kisan AI'),
                              _FeaturePill(icon: '🌡️', label: 'Weather'),
                              _FeaturePill(icon: '📊', label: 'Mandi Rates'),
                              _FeaturePill(icon: '📺', label: 'Krishi TV'),
                              _FeaturePill(icon: '🔬', label: 'Crop Doctor'),
                              _FeaturePill(icon: '🏛️', label: 'Schemes'),
                            ],
                          ),
                          SizedBox(height: r.rs(24)),

                          // CTA Button
                          GestureDetector(
                            onTap: () => context.push('/auth/login?role=FARMER'),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(vertical: r.rs(16)),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(r.rs(16)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: r.rs(12),
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'I am a Farmer — Let\'s Start',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: r.sp(16),
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.farmerAccent,
                                    ),
                                  ),
                                  SizedBox(width: r.rs(10)),
                                  Container(
                                    width: r.rs(28), height: r.rs(28),
                                    decoration: BoxDecoration(
                                      color: AppColors.farmerTint,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.arrow_forward_rounded,
                                        color: AppColors.farmerAccent, size: r.rs(16)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: r.rs(32)),

                  // ── Trust badges ─────────────────────────────────────
                  FadeInUp(
                    delay: const Duration(milliseconds: 400),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _TrustBadge(icon: '🛡️', label: 'Secure'),
                        _TrustBadge(icon: '🌐', label: 'Hindi / मराठी'),
                        _TrustBadge(icon: '🆓', label: 'Free to Use'),
                      ],
                    ),
                  ),

                  SizedBox(height: r.rs(32)),

                  // ── Footer ────────────────────────────────────────────
                  FadeInUp(
                    delay: const Duration(milliseconds: 500),
                    child: Column(
                      children: [
                        Text(
                          '🇮🇳  ${l10n.tagline}',
                          style: GoogleFonts.inter(
                            fontSize: r.sp(12),
                            color: AppColors.muted.withValues(alpha: 0.7),
                          ),
                        ),
                        SizedBox(height: r.rs(16)),
                        // Hidden business link — 5 taps to unlock
                        GestureDetector(
                          onTap: _onBusinessTap,
                          child: Text(
                            'Business login',
                            style: GoogleFonts.inter(
                              fontSize: r.sp(12),
                              color: AppColors.muted.withValues(alpha: 0.35),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        SizedBox(height: r.rs(24)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _FeaturePill extends StatelessWidget {
  final String icon, label;
  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: r.rs(10), vertical: r.rh(5)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(r.rs(20)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: TextStyle(fontSize: r.sp(12))),
          SizedBox(width: r.rs(5)),
          Text(label, style: GoogleFonts.inter(
            fontSize: r.sp(11), fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final String icon, label;
  const _TrustBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Column(
      children: [
        Text(icon, style: TextStyle(fontSize: r.sp(22))),
        SizedBox(height: r.rh(4)),
        Text(label, style: GoogleFonts.inter(
          fontSize: r.sp(11), fontWeight: FontWeight.w600, color: AppColors.muted)),
      ],
    );
  }
}

class _BizRoleBtn extends StatelessWidget {
  final String emoji, label;
  final Color accent, tint;
  final VoidCallback onTap;
  const _BizRoleBtn({required this.emoji, required this.label,
      required this.accent, required this.tint, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(r.rs(16)),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(r.rs(16)),
          border: Border.all(color: accent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Text(emoji, style: TextStyle(fontSize: r.sp(24))),
            SizedBox(width: r.rs(14)),
            Expanded(child: Text(label, style: GoogleFonts.spaceGrotesk(
              fontSize: r.sp(16), fontWeight: FontWeight.w700, color: accent))),
            Icon(Icons.arrow_forward_ios_rounded, color: accent, size: r.sp(16)),
          ],
        ),
      ),
    );
  }
}
