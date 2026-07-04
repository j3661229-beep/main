import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../core/constants/app_constants.dart';

class FarmerProfileScreen extends ConsumerWidget {
  const FarmerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final name = user?.name ?? 'Farmer';
    final phone = user?.phone ?? '';
    final initials = name.isNotEmpty ? name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase() : 'F';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.farmerAccent,
            leading: const SizedBox(),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.farmerGradient),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                        child: Center(child: Text(initials, style: GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white))),
                      ),
                      const SizedBox(height: 12),
                      Text(name, style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                      if (phone.isNotEmpty) Text(phone, style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.8))),
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

                  // Farm Details Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border), boxShadow: AppColors.softShadow),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.farmerTint, borderRadius: BorderRadius.circular(10)), child: const Center(child: Text('🌾', style: TextStyle(fontSize: 18)))),
                            const SizedBox(width: 12),
                            Text('Farm Details', style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _InfoRow(label: 'Village', value: (user?.farmer as Map?)?['village'] ?? '-'),
                        _InfoRow(label: 'District', value: (user?.farmer as Map?)?['district'] ?? (user?.district ?? '-')),
                        _InfoRow(label: 'Land Size', value: '${(user?.farmer as Map?)?['landSize'] ?? '-'} acres'),
                        _InfoRow(label: 'Crops', value: ((user?.farmer as Map?)?['primaryCrops'] as List?)?.join(', ') ?? '-'),
                        _InfoRow(label: 'Language', value: AppConstants.languages[(user?.farmer as Map?)?['language']] ?? 'English'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Settings
                  Text('Settings', style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border), boxShadow: AppColors.softShadow),
                    child: Column(
                      children: [
                        _SettingsTile(icon: Icons.language_outlined, color: AppColors.farmerAccent, label: 'Language', onTap: () {}),
                        const Divider(height: 1, color: AppColors.border),
                        _SettingsTile(icon: Icons.notifications_outlined, color: AppColors.supplierAccent, label: 'Notifications', onTap: () {}),
                        const Divider(height: 1, color: AppColors.border),
                        _SettingsTile(icon: Icons.help_outline_rounded, color: AppColors.dealerAccent, label: 'Help & Support', onTap: () {}),
                        const Divider(height: 1, color: AppColors.border),
                        _SettingsTile(
                          icon: Icons.logout_rounded,
                          color: AppColors.danger,
                          label: 'Log Out',
                          onTap: () => _confirmLogout(context, ref),
                          textColor: AppColors.danger,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(child: Text('AgriMart v1.0.0', style: GoogleFonts.inter(fontSize: 12, color: AppColors.placeholder))),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Log Out?', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
        content: Text('You will be logged out of AgriMart.', style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.muted))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Log Out', style: GoogleFonts.inter(color: AppColors.danger, fontWeight: FontWeight.w600))),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted)),
        Flexible(child: Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink), textAlign: TextAlign.right)),
      ],
    ),
  );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  final Color? textColor;
  const _SettingsTile({required this.icon, required this.color, required this.label, required this.onTap, this.textColor});

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    leading: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: color, size: 20),
    ),
    title: Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: textColor ?? AppColors.ink)),
    trailing: textColor != null ? null : const Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 20),
  );
}

