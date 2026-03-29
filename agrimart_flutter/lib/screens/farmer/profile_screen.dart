import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shimmer.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('⚙️ Profile & Settings',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: auth.isLoading && user == null
          ? const AppShimmerProfileLayout()
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10))
                      ]),
                  child: Column(children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: AppColors.primaryLight, width: 4),
                      ),
                      child: CircleAvatar(
                          radius: 44,
                          backgroundColor: AppColors.background,
                          child: Text(user?.isFarmer == true ? '👨‍🌾' : '🚛',
                              style: const TextStyle(fontSize: 40))),
                    ),
                    const SizedBox(height: 16),
                    Text(user?.name ?? 'AgriMart User',
                        style: AppTextStyles.headingXL),
                    const SizedBox(height: 4),
                    Text(user?.phone ?? '+91 xxxxxx',
                        style: AppTextStyles.bodyMD
                            .copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(
                            user?.isFarmer == true
                                ? 'Verified Farmer'
                                : 'Verified Supplier',
                            style: const TextStyle(
                                color: AppColors.primaryDark,
                                fontSize: 12,
                                fontWeight: FontWeight.w800))),
                  ]),
                ),
                const SizedBox(height: 32),
                _sectionHeader('ACCOUNT MANAGEMENT'),
                _buildItem(
                    Icons.language, 'App Language', 'मराठी (Marathi)', () {}),
                _buildItem(Icons.location_on_outlined, 'My Farm Address',
                    'Manage saved locations', () {}),
                _buildItem(
                    Icons.notifications_outlined,
                    'Notification Settings',
                    'Manage SMS & WhatsApp alerts',
                    () {}),
                _buildItem(Icons.security, 'Privacy & Security',
                    'Data controls & permissions', () {}),
                const SizedBox(height: 24),
                _sectionHeader('SUPPORT & LEGAL'),
                _buildItem(Icons.help_outline, 'Help Center',
                    'FAQs & Customer Support', () {}),
                _buildItem(Icons.article_outlined, 'Terms of Service',
                    'Platform agreements & legal', () {}),
                _buildItem(Icons.info_outline, 'About AgriMart',
                    'Version 1.0.0 (Production)', () {}),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: TextButton.icon(
                    onPressed: () {
                      ref.read(authProvider.notifier).logout();
                    },
                    icon: const Icon(Icons.logout),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: AppColors.error.withValues(alpha: 0.08),
                      foregroundColor: AppColors.error,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    label: const Text('Log Out From Device',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 64),
              ],
            ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(title,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textTertiary,
              letterSpacing: 1.5)),
    );
  }

  Widget _buildItem(
      IconData icon, String title, String sub, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.primary, size: 22)),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        subtitle: Text(sub,
            style:
                const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
        trailing: const Icon(Icons.arrow_forward_ios,
            size: 12, color: AppColors.textTertiary),
      ),
    );
  }
}
