import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:agrimart/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});
  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  String? _hoveredRole;

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final l10n = AppLocalizations.of(context)!;

    final roles = [
      {
        'role': 'FARMER',
        'emoji': '🌾',
        'title': l10n.farmerRole,
        'subtitle': l10n.farmerRoleDesc,
        'accent': AppColors.farmerAccent,
        'tint': AppColors.farmerTint,
      },
      {
        'role': 'SUPPLIER',
        'emoji': '🏪',
        'title': l10n.supplierRole,
        'subtitle': l10n.supplierRoleDesc,
        'accent': AppColors.supplierAccent,
        'tint': AppColors.supplierTint,
      },
      {
        'role': 'DEALER',
        'emoji': '🤝',
        'title': l10n.dealerRole,
        'subtitle': l10n.dealerRoleDesc,
        'accent': AppColors.dealerAccent,
        'tint': AppColors.dealerTint,
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 48),
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: AppColors.farmerGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppColors.primaryShadow,
                      ),
                      child: Center(child: Text('🌱', style: TextStyle(fontSize: r.sp(36)))),
                    ),
                    const SizedBox(height: 16),
                    Text('AgriMart', style: GoogleFonts.spaceGrotesk(fontSize: r.sp(32), fontWeight: FontWeight.w800, color: AppColors.ink)),
                    const SizedBox(height: 6),
                    Text(l10n.indianAgriMarketplace, style: GoogleFonts.inter(fontSize: r.sp(14), color: AppColors.muted)),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: Text(l10n.selectYourRole, style: GoogleFonts.spaceGrotesk(fontSize: r.sp(22), fontWeight: FontWeight.w700, color: AppColors.ink)),
              ),
              const SizedBox(height: 32),
              ...List.generate(roles.length, (i) {
                final roleData = roles[i];
                final accent = roleData['accent'] as Color;
                final tint = roleData['tint'] as Color;
                final role = roleData['role'] as String;
                return FadeInUp(
                  delay: Duration(milliseconds: 400 + i * 100),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      onTap: () => context.push('/auth/login?role=$role'),
                      onTapDown: (_) => setState(() => _hoveredRole = role),
                      onTapUp: (_) => setState(() => _hoveredRole = null),
                      onTapCancel: () => setState(() => _hoveredRole = null),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _hoveredRole == role ? tint : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _hoveredRole == role ? accent : AppColors.border,
                            width: _hoveredRole == role ? 2 : 1,
                          ),
                          boxShadow: _hoveredRole == role ? AppColors.softShadow : [],
                        ),
                        child: Row(
                          children: [
                            CustomPaint(
                              size: const Size(64, 64),
                              painter: _DashedCirclePainter(color: accent),
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
                                child: Center(child: Text(roleData['emoji'] as String, style: TextStyle(fontSize: r.sp(28)))),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(roleData['title'] as String, style: GoogleFonts.spaceGrotesk(fontSize: r.sp(18), fontWeight: FontWeight.w700, color: AppColors.ink)),
                                  const SizedBox(height: 4),
                                  Text(roleData['subtitle'] as String, style: GoogleFonts.inter(fontSize: r.sp(12), color: AppColors.muted, height: 1.5)),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios_rounded, color: accent, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 40),
              FadeInUp(
                delay: const Duration(milliseconds: 700),
                child: Text('🇮🇳  ${l10n.tagline}', style: GoogleFonts.inter(fontSize: r.sp(12), color: AppColors.muted.withValues(alpha: 0.7))),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  _DashedCirclePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 2..style = PaintingStyle.stroke;
    const count = 20;
    const da = 2 * 3.14159265 / count;
    final r = size.width / 2 - 3;
    final c = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i < count; i++) {
      final s = (i * da) - 3.14159265 / 2;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), s, da * 0.55, false, paint);
    }
  }
  @override
  bool shouldRepaint(_DashedCirclePainter old) => old.color != color;
}
