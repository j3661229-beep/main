import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/providers/auth_provider.dart';
import '../../core/utils/responsive.dart';

class SupplierProfileScreen extends ConsumerWidget {
  const SupplierProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.r;
    final user = ref.watch(authProvider).user;
    final supplier = user?.supplier as Map? ?? {};
    final bizName = supplier['businessName'] ?? user?.name ?? 'Supplier';
    final ownerName = supplier['ownerName'] ?? user?.name ?? '';
    final gstin    = supplier['gstin'] ?? '-';
    final city     = supplier['city'] ?? '-';
    final district = supplier['district'] ?? user?.district ?? '-';
    final cats     = (supplier['categories'] as List?)?.join(', ') ?? '-';
    final isVerified = user?.isVerified ?? false;
    final initials = bizName.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: r.heroHeaderHeight,
            pinned: true,
            backgroundColor: AppColors.supplierAccent,
            leading: const SizedBox(),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.supplierGradient),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: r.rs(80), height: 80,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                        child: Center(child: Text(initials, style: GoogleFonts.spaceGrotesk(fontSize: r.sp(28), fontWeight: FontWeight.w700, color: Colors.white))),
                      ),
                      SizedBox(height: r.rh(10)),
                      Text(bizName, style: GoogleFonts.spaceGrotesk(fontSize: r.sp(20), fontWeight: FontWeight.w700, color: Colors.white)),
                      SizedBox(height: r.rh(4)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(isVerified ? Icons.verified_rounded : Icons.schedule_rounded, color: Colors.white.withValues(alpha: 0.8), size: 14),
                          SizedBox(width: r.rs(4)),
                          Text(isVerified ? 'Verified Supplier' : 'Verification Pending', style: GoogleFonts.inter(fontSize: r.sp(12), color: Colors.white.withValues(alpha: 0.8))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: ResponsiveLayout(
              applyPadding: false,
              child: Padding(
              padding: EdgeInsets.fromLTRB(r.horizontalPadding, r.rs(16), r.horizontalPadding, r.bottomNavInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Business details
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CardHeader(emoji: '🏪', title: 'Business Details'),
                        SizedBox(height: r.rh(16)),
                        _InfoRow('Business Name', bizName),
                        _InfoRow('Owner Name', ownerName),
                        _InfoRow('GSTIN', gstin),
                        _InfoRow('City', city),
                        _InfoRow('District', district),
                        _InfoRow('Categories', cats),
                        _InfoRow('Verification', isVerified ? '✅ Verified' : '⏳ Pending'),
                      ],
                    ),
                  ),
                  SizedBox(height: r.rh(20)),

                  Text('Settings', style: GoogleFonts.spaceGrotesk(fontSize: r.sp(15), fontWeight: FontWeight.w700, color: AppColors.ink)),
                  SizedBox(height: r.rh(10)),
                  _Card(
                    child: Column(children: [
                      _SettingsTile(icon: Icons.business_outlined,   color: AppColors.supplierAccent, label: 'Business Settings', onTap: () {}),
                      Divider(height: r.rh(1), color: AppColors.border),
                      _SettingsTile(icon: Icons.account_balance_outlined, color: AppColors.success, label: 'Payout Details', onTap: () {}),
                      Divider(height: r.rh(1), color: AppColors.border),
                      _SettingsTile(icon: Icons.help_outline_rounded,    color: AppColors.dealerAccent, label: 'Help & Support', onTap: () {}),
                      Divider(height: r.rh(1), color: AppColors.border),
                      _SettingsTile(icon: Icons.logout_rounded, color: AppColors.danger, label: 'Log Out', textColor: AppColors.danger, onTap: () => _confirmLogout(context, ref)),
                    ]),
                  ),
                  SizedBox(height: r.bottomNavInset),
                ],
              ),
            ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) async {
    final r = context.r;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.rs(20))),
        title: Text('Log Out?', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
        content: Text('You will be logged out.', style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.muted))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Log Out', style: GoogleFonts.inter(color: AppColors.danger, fontWeight: FontWeight.w600))),
        ],
      ),
    );
    if (ok == true) await ref.read(authProvider.notifier).logout();
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Container(
    padding: EdgeInsets.all(r.rs(20)),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(r.rs(20)), border: Border.all(color: AppColors.border), boxShadow: AppColors.softShadow),
    child: child,
  );
  }
}

class _CardHeader extends StatelessWidget {
  final String emoji, title;
  const _CardHeader({required this.emoji, required this.title});
  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Row(children: [
    Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.supplierTint, borderRadius: BorderRadius.circular(r.rs(10))), child: Center(child: Text(emoji, style: TextStyle(fontSize: r.sp(18))))),
    SizedBox(width: r.rs(12)),
    Text(title, style: GoogleFonts.spaceGrotesk(fontSize: r.sp(15), fontWeight: FontWeight.w700, color: AppColors.ink)),
  ]);
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Padding(
    padding: EdgeInsets.symmetric(vertical: r.rh(5)),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: GoogleFonts.inter(fontSize: r.sp(13), color: AppColors.muted)),
      Flexible(child: Text(value, style: GoogleFonts.inter(fontSize: r.sp(13), fontWeight: FontWeight.w500, color: AppColors.ink), textAlign: TextAlign.right)),
    ]),
  );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon; final Color color; final String label; final VoidCallback onTap; final Color? textColor;
  const _SettingsTile({required this.icon, required this.color, required this.label, required this.onTap, this.textColor});
  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return ListTile(
    onTap: onTap,
    leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(r.rs(10))), child: Icon(icon, color: color, size: r.sp(20))),
    title: Text(label, style: GoogleFonts.inter(fontSize: r.sp(14), fontWeight: FontWeight.w500, color: textColor ?? AppColors.ink)),
    trailing: textColor != null ? null : Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: r.sp(20)),
  );
  }
}

