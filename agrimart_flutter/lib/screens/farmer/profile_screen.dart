import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/widgets/language_picker_sheet.dart';
import 'package:agrimart/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shimmer.dart';
import '../../core/utils/responsive.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.r;
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
              padding: EdgeInsets.all(r.rs(20)),
              children: [
                Container(
                  padding: EdgeInsets.all(r.rs(24)),
                  decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(r.rs(24)),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.05),
                            blurRadius: r.rs(20),
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
                              style: TextStyle(fontSize: r.sp(40)))),
                    ),
                    SizedBox(height: r.rh(16)),
                    Text(user?.name ?? 'AgriMart User',
                        style: AppTextStyles.headingXL),
                    SizedBox(height: r.rh(4)),
                    Text(user?.phone ?? '+91 xxxxxx',
                        style: AppTextStyles.bodyMD
                            .copyWith(color: AppColors.textSecondary)),
                    SizedBox(height: r.rh(16)),
                    Container(
                        padding: EdgeInsets.symmetric(horizontal: r.rs(16), vertical: r.rh(6)),
                        decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(r.rs(20))),
                        child: Text(
                            user?.isFarmer == true
                                ? 'Verified Farmer'
                                : 'Verified Supplier',
                            style: TextStyle(
                                color: AppColors.primaryDark,
                                fontSize: r.sp(12),
                                fontWeight: FontWeight.w800))),
                  ]),
                ),
                SizedBox(height: r.rh(32)),
                _sectionHeader(r, l10n.accountManagement.toUpperCase()),
                _buildItem(r, Icons.language, l10n.appLanguage, langName, () {
                  showLanguagePickerSheet(context, ref);
                }),
                _buildItem(r, Icons.location_on_outlined, 'My Farm Address',
                    'Manage saved locations', () {
                  _showStubSheet(context, '📍 Farm Locations', 
                      'Add or edit your village and operational pin codes for seamless order delivery and accurate weather alerts.');
                }),
                _buildItem(r, Icons.calendar_month_outlined, 'My Delivery Slots',
                    'View your booked slots with dealers', () {
                  context.push('/farmer/trade/bookings');
                }),
                _buildItem(r,
                    Icons.notifications_outlined,
                    'Notification Settings',
                    'Manage SMS & WhatsApp alerts',
                    () {
                  _showStubSheet(context, '🔔 Notification Preferences', 
                      'Toggle push notifications, Daily Mandi SMS alerts, and WhatsApp updates for your orders.');
                }),
                _buildItem(r, Icons.security, 'Privacy & Security',
                    'Data controls & permissions', () {
                  _showStubSheet(context, '🛡️ Privacy & Security', 
                      'Manage data sharing settings, device permissions, and activity history.');
                }),
                SizedBox(height: r.rh(24)),
                _sectionHeader(r, l10n.supportLegal.toUpperCase()),
                _buildItem(r, Icons.help_outline, l10n.helpCenter,
                    'FAQs & Customer Support', () {
                   _showStubSheet(context, '💬 Need Help?', 
                      'Contact our 24/7 Kisan Helpline at 1800-120-120\nor email support@agrimart.in');
                }),
                _buildItem(r, Icons.article_outlined, l10n.termsOfService,
                    'Platform agreements & legal', () {
                  _showStubSheet(context, '📄 ${l10n.termsOfService}', 
                      'By using AgriMart, you agree to our fair usage policy and zero-commission structure (for first year).');
                }),
                _buildItem(r, Icons.info_outline, l10n.aboutUs,
                    'Version 1.0.0 (Production)', () {
                  _showStubSheet(context, '🌾 ${l10n.aboutUs}', 
                      'AgriMart v1.0.0\nBuilt for the farmers of India to provide direct market access, AI crop tools, and transparent pricing.');
                }),
                SizedBox(height: r.rh(40)),
                SizedBox(
                  width: double.infinity,
                  height: r.rh(56),
                  child: TextButton.icon(
                    onPressed: () {
                      ref.read(authProvider.notifier).logout();
                    },
                    icon: const Icon(Icons.logout),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.all(r.rs(16)),
                      backgroundColor: AppColors.error.withValues(alpha: 0.08),
                      foregroundColor: AppColors.error,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(r.rs(16))),
                    ),
                    label: Text(l10n.logout,
                        style: TextStyle(
                            fontSize: r.sp(16), fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(height: r.rh(64)),
              ],
            ),
    );
  }



  void _showStubSheet(BuildContext context, String title, String body) {
    final r = context.r;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(r.rs(32)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: AppTextStyles.headingLG, textAlign: TextAlign.center),
              SizedBox(height: r.rh(24)),
              Text(body, style: AppTextStyles.bodyLG.copyWith(height: 1.5), textAlign: TextAlign.center),
              SizedBox(height: r.rh(32)),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Got it'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(Responsive r, String title) {
    return Padding(
      padding: EdgeInsets.only(left: r.rs(4), bottom: r.rh(12)),
      child: Text(title,
          style: TextStyle(
              fontSize: r.sp(12),
              fontWeight: FontWeight.w800,
              color: AppColors.textTertiary,
              letterSpacing: 1.5)),
    );
  }

  Widget _buildItem(
      Responsive r, IconData icon, String title, String sub, VoidCallback onTap) {
    return Container(
      margin: EdgeInsets.only(bottom: r.rh(12)),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(r.rs(18)),
          border: Border.all(color: AppColors.border)),
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(horizontal: r.rs(16), vertical: r.rh(4)),
        leading: Container(
            padding: EdgeInsets.all(r.rs(10)),
            decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(r.rs(12))),
            child: Icon(icon, color: AppColors.primary, size: r.sp(22))),
        title: Text(title,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: r.sp(15))),
        subtitle: Text(sub,
            style:
                TextStyle(fontSize: r.sp(12), color: AppColors.textTertiary)),
        trailing: Icon(Icons.arrow_forward_ios,
            size: r.sp(12), color: AppColors.textTertiary),
      ),
    );
  }
}

