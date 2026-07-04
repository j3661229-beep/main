import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/providers/auth_provider.dart';

class DealerProfileScreen extends ConsumerWidget {
  const DealerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user   = ref.watch(authProvider).user;
    final dealer = user?.dealer as Map? ?? {};
    final bizName    = dealer['businessName'] ?? user?.name ?? 'Dealer';
    final ownerName  = dealer['ownerName']   ?? user?.name ?? '';
    final license    = dealer['mandiLicense'] ?? dealer['license'] ?? '-';
    final apmc       = dealer['apmcYard']    ?? dealer['location'] ?? '-';
    final commodities = (dealer['commodities'] as List?)?.join(', ') ?? '-';
    final isVerified  = user?.isVerified ?? false;
    final initials   = bizName.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 210,
            pinned: true,
            backgroundColor: AppColors.dealerAccent,
            leading: const SizedBox(),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.dealerGradient),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                        child: Center(child: Text(initials, style: GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white))),
                      ),
                      const SizedBox(height: 10),
                      Text(bizName, style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(isVerified ? Icons.verified_rounded : Icons.schedule_rounded, color: Colors.white.withValues(alpha: 0.8), size: 14),
                          const SizedBox(width: 4),
                          Text(isVerified ? 'Verified Dealer' : 'Verification Pending', style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CardHeader(emoji: '🤝', title: 'Business Details', accent: AppColors.dealerAccent, tint: AppColors.dealerTint),
                        const SizedBox(height: 16),
                        _InfoRow('Business Name', bizName),
                        _InfoRow('Owner Name', ownerName),
                        _InfoRow('Mandi License', license),
                        _InfoRow('APMC Yard', apmc),
                        _InfoRow('Commodities', commodities),
                        _InfoRow('Verification', isVerified ? '✅ Verified' : '⏳ Pending'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Settings', style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  const SizedBox(height: 10),
                  _Card(
                    child: Column(children: [
                      _SettingsTile(icon: Icons.business_outlined,   color: AppColors.dealerAccent, label: 'Business Settings', onTap: () {}),
                      const Divider(height: 1, color: AppColors.border),
                      _SettingsTile(icon: Icons.account_balance_outlined, color: AppColors.success, label: 'Payout Details', onTap: () {}),
                      const Divider(height: 1, color: AppColors.border),
                      _SettingsTile(icon: Icons.help_outline_rounded, color: AppColors.supplierAccent, label: 'Help & Support', onTap: () {}),
                      const Divider(height: 1, color: AppColors.border),
                      _SettingsTile(icon: Icons.logout_rounded, color: AppColors.danger, label: 'Log Out', textColor: AppColors.danger, onTap: () => _confirmLogout(context, ref)),
                    ]),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border), boxShadow: AppColors.softShadow),
    child: child,
  );
}

class _CardHeader extends StatelessWidget {
  final String emoji, title; final Color accent, tint;
  const _CardHeader({required this.emoji, required this.title, required this.accent, required this.tint});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 36, height: 36, decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(10)), child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18)))),
    const SizedBox(width: 12),
    Text(title, style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
  ]);
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted)),
      Flexible(child: Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink), textAlign: TextAlign.right)),
    ]),
  );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon; final Color color; final String label; final VoidCallback onTap; final Color? textColor;
  const _SettingsTile({required this.icon, required this.color, required this.label, required this.onTap, this.textColor});
  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)),
    title: Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: textColor ?? AppColors.ink)),
    trailing: textColor != null ? null : const Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 20),
  );
}

