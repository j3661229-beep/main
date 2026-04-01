import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/auth_provider.dart';
import '../../core/providers/locale_provider.dart';
import 'package:agrimart/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shimmer.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final locale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context)!;

    final langName = locale.languageCode == 'hi' ? 'हिंदी (Hindi)' : locale.languageCode == 'mr' ? 'मराठी (Marathi)' : 'English';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('⚙️ ${l10n.profile}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
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
                _sectionHeader(l10n.accountManagement.toUpperCase()),
                _buildItem(Icons.language, l10n.appLanguage, langName, () {
                  _showLanguagePicker(context, ref, locale);
                }),
                _buildItem(Icons.location_on_outlined, 'My Farm Address',
                    'Manage saved locations', () {
                  _showStubSheet(context, '📍 Farm Locations', 
                      'Add or edit your village and operational pin codes for seamless order delivery and accurate weather alerts.');
                }),
                _buildItem(
                    Icons.notifications_outlined,
                    'Notification Settings',
                    'Manage SMS & WhatsApp alerts',
                    () {
                  _showStubSheet(context, '🔔 Notification Preferences', 
                      'Toggle push notifications, Daily Mandi SMS alerts, and WhatsApp updates for your orders.');
                }),
                _buildItem(Icons.security, 'Privacy & Security',
                    'Data controls & permissions', () {
                  _showStubSheet(context, '🛡️ Privacy & Security', 
                      'Manage data sharing settings, device permissions, and activity history.');
                }),
                const SizedBox(height: 24),
                _sectionHeader(l10n.supportLegal.toUpperCase()),
                _buildItem(Icons.help_outline, l10n.helpCenter,
                    'FAQs & Customer Support', () {
                   _showStubSheet(context, '💬 Need Help?', 
                      'Contact our 24/7 Kisan Helpline at 1800-120-120\nor email support@agrimart.in');
                }),
                _buildItem(Icons.article_outlined, l10n.termsOfService,
                    'Platform agreements & legal', () {
                  _showStubSheet(context, '📄 ${l10n.termsOfService}', 
                      'By using AgriMart, you agree to our fair usage policy and zero-commission structure (for first year).');
                }),
                _buildItem(Icons.info_outline, l10n.aboutUs,
                    'Version 1.0.0 (Production)', () {
                  _showStubSheet(context, '🌾 ${l10n.aboutUs}', 
                      'AgriMart v1.0.0\nBuilt for the farmers of India to provide direct market access, AI crop tools, and transparent pricing.');
                }),
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
                    label: Text(l10n.logout,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 64),
              ],
            ),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref, Locale currentLocale) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Language / भाषा निवडा', style: AppTextStyles.headingLG),
              const SizedBox(height: 16),
              ...[
                {'name': 'English', 'code': 'en'},
                {'name': 'मराठी (Marathi)', 'code': 'mr'},
                {'name': 'हिंदी (Hindi)', 'code': 'hi'}
              ].map((l) {
                final isSelected = currentLocale.languageCode == l['code'];
                return ListTile(
                  title: Text(l['name']!, style: isSelected ? AppTextStyles.headingMD.copyWith(color: AppColors.primary) : AppTextStyles.bodyLG),
                  trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: isSelected ? AppColors.primarySurface : null,
                  onTap: () {
                    ref.read(localeProvider.notifier).setLocale(Locale(l['code']!));
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showStubSheet(BuildContext context, String title, String body) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: AppTextStyles.headingLG, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Text(body, style: AppTextStyles.bodyLG.copyWith(height: 1.5), textAlign: TextAlign.center),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        ),
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
