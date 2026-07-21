import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agrimart/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/widgets/language_picker_sheet.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/services/api_service.dart';
import '../../core/utils/responsive.dart';

class FarmerProfileScreen extends ConsumerStatefulWidget {
  const FarmerProfileScreen({super.key});

  @override
  ConsumerState<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends ConsumerState<FarmerProfileScreen> {
  bool _editing = false;
  bool _saving = false;
  late TextEditingController _villageCtrl;
  late TextEditingController _districtCtrl;
  late TextEditingController _landCtrl;
  late TextEditingController _cropsCtrl;

  @override
  void initState() {
    super.initState();
    _villageCtrl = TextEditingController();
    _districtCtrl = TextEditingController();
    _landCtrl = TextEditingController();
    _cropsCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFromUser());
  }

  @override
  void dispose() {
    _villageCtrl.dispose();
    _districtCtrl.dispose();
    _landCtrl.dispose();
    _cropsCtrl.dispose();
    super.dispose();
  }

  void _loadFromUser() {
    final farmer = ref.read(authProvider).user?.farmer as Map?;
    if (farmer == null) return;
    _villageCtrl.text = farmer['village']?.toString() ?? '';
    _districtCtrl.text = farmer['district']?.toString() ?? ref.read(authProvider).user?.district ?? '';
    _landCtrl.text = _farmSizeText(farmer);
    _cropsCtrl.text = _cropsText(farmer);
  }

  String _farmSizeText(Map? farmer) {
    final v = farmer?['farmSizeAcres'] ?? farmer?['landSize'];
    if (v == null) return '';
    return v.toString();
  }

  String _cropsText(Map? farmer) {
    final list = _cropsList(farmer);
    if (list == null || list.isEmpty) return '';
    return list.map((e) => e.toString()).join(', ');
  }

  List? _cropsList(Map? farmer) =>
      (farmer?['currentCrops'] as List?) ?? (farmer?['primaryCrops'] as List?);

  String _languageLabel(AppLocalizations l10n) {
    final code = ref.watch(localeProvider).languageCode;
    return code == 'hi' ? l10n.hindi : code == 'mr' ? l10n.marathi : l10n.english;
  }

  Future<void> _saveProfile(AppLocalizations l10n) async {
    setState(() => _saving = true);
    try {
      await ApiService.instance.updateFarmDetails({
        'village': _villageCtrl.text.trim(),
        'district': _districtCtrl.text.trim(),
        'farmSizeAcres': double.tryParse(_landCtrl.text.trim()),
        'currentCrops': _cropsCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      });
      await ref.read(authProvider.notifier).refreshUser();
      if (mounted) {
        _loadFromUser();
        setState(() => _editing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.profileUpdated)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authProvider).user;
    final name = user?.name ?? 'Farmer';
    final phone = user?.phone ?? '';
    final initials = name.isNotEmpty ? name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase() : 'F';
    final farmer = user?.farmer as Map?;
    final farmSize = _farmSizeText(farmer);
    final crops = _cropsText(farmer);

    ref.listen(authProvider, (prev, next) {
      if (!_editing && next.user?.farmer != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_editing) _loadFromUser();
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: r.heroHeaderHeight,
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
                        width: r.rs(80),
                        height: r.rh(80),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(initials, style: GoogleFonts.spaceGrotesk(fontSize: r.sp(28), fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                      SizedBox(height: r.rh(12)),
                      Text(name, style: GoogleFonts.spaceGrotesk(fontSize: r.sp(20), fontWeight: FontWeight.w700, color: Colors.white)),
                      if (phone.isNotEmpty) Text(phone, style: GoogleFonts.inter(fontSize: r.sp(13), color: Colors.white.withValues(alpha: 0.8))),
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
                    Container(
                      padding: EdgeInsets.all(r.rs(20)),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(r.rs(20)),
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppColors.softShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: r.rs(36),
                                height: r.rh(36),
                                decoration: BoxDecoration(color: AppColors.farmerTint, borderRadius: BorderRadius.circular(r.rs(10))),
                                child: Center(child: Text('🌾', style: TextStyle(fontSize: r.sp(18)))),
                              ),
                              SizedBox(width: r.rs(12)),
                              Expanded(
                                child: Text(l10n.farmDetails, style: GoogleFonts.spaceGrotesk(fontSize: r.sp(15), fontWeight: FontWeight.w700, color: AppColors.ink)),
                              ),
                              TextButton(
                                onPressed: () {
                                  if (!_editing) _loadFromUser();
                                  setState(() => _editing = !_editing);
                                },
                                child: Text(_editing ? l10n.cancel : l10n.editFarmProfile, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.farmerAccent)),
                              ),
                            ],
                          ),
                          SizedBox(height: r.rh(16)),
                          if (_editing) ...[
                            _EditField(label: l10n.villageLabel, controller: _villageCtrl),
                            _EditField(label: l10n.districtLabel, controller: _districtCtrl),
                            _EditField(label: l10n.landSizeLabel, controller: _landCtrl, keyboard: TextInputType.number),
                            _EditField(label: l10n.cropsLabel, controller: _cropsCtrl),
                            SizedBox(height: r.rh(12)),
                            AppButton(
                              label: l10n.saveChanges,
                              onTap: _saving ? null : () => _saveProfile(l10n),
                              color: AppColors.farmerAccent,
                              isLoading: _saving,
                            ),
                          ] else ...[
                            _InfoRow(label: l10n.villageLabel, value: farmer?['village']?.toString() ?? '-'),
                            _InfoRow(label: l10n.districtLabel, value: farmer?['district']?.toString() ?? (user?.district ?? '-')),
                            _InfoRow(label: l10n.landSizeLabel, value: '${farmSize.isEmpty ? '-' : farmSize} ${l10n.acresUnit}'),
                            _InfoRow(label: l10n.cropsLabel, value: crops.isEmpty ? '-' : crops),
                            _InfoRow(label: l10n.languageLabel, value: _languageLabel(l10n)),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: r.rh(20)),
                    Text(l10n.settings, style: GoogleFonts.spaceGrotesk(fontSize: r.sp(15), fontWeight: FontWeight.w700, color: AppColors.ink)),
                    SizedBox(height: r.rh(10)),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(r.rs(16)),
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppColors.softShadow,
                      ),
                      child: Column(
                        children: [
                          _SettingsTile(
                            icon: Icons.language_outlined,
                            color: AppColors.farmerAccent,
                            label: l10n.languageLabel,
                            trailing: _languageLabel(l10n),
                            onTap: () => showLanguagePickerSheet(context, ref),
                          ),
                          Divider(height: r.rh(1), color: AppColors.border),
                          _SettingsTile(icon: Icons.notifications_outlined, color: AppColors.supplierAccent, label: l10n.notifications, onTap: () => context.push('/notifications')),
                          Divider(height: r.rh(1), color: AppColors.border),
                          _SettingsTile(icon: Icons.help_outline_rounded, color: AppColors.dealerAccent, label: l10n.helpSupport, onTap: () => _showHelpSheet(context, l10n)),
                          Divider(height: r.rh(1), color: AppColors.border),
                          _SettingsTile(
                            icon: Icons.logout_rounded,
                            color: AppColors.danger,
                            label: l10n.logOut,
                            onTap: () => _confirmLogout(context, ref, l10n),
                            textColor: AppColors.danger,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: r.rh(32)),
                    Center(child: Text('AgriMart v1.0.0', style: GoogleFonts.inter(fontSize: r.sp(12), color: AppColors.placeholder))),
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

  void _showHelpSheet(BuildContext context, AppLocalizations l10n) {
    final r = context.r;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.all(r.rs(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('💬 ${l10n.helpSupport}', style: GoogleFonts.spaceGrotesk(fontSize: r.sp(18), fontWeight: FontWeight.w700)),
            SizedBox(height: r.rh(12)),
            Text(
              'Kisan Helpline: 1800-120-120\nEmail: support@agrimart.in',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: r.sp(14), height: 1.5, color: AppColors.muted),
            ),
            SizedBox(height: r.rh(20)),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.continueBtn),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final r = context.r;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.rs(20))),
        title: Text(l10n.logOutConfirmTitle, style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
        content: Text(l10n.logOutConfirmMessage, style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel, style: GoogleFonts.inter(color: AppColors.muted))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.logOut, style: GoogleFonts.inter(color: AppColors.danger, fontWeight: FontWeight.w600))),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
    }
  }
}

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboard;

  const _EditField({required this.label, required this.controller, this.keyboard = TextInputType.text});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Padding(
      padding: EdgeInsets.only(bottom: r.rh(12)),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(r.rs(12)), borderSide: BorderSide(color: AppColors.border)),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Padding(
    padding: EdgeInsets.symmetric(vertical: r.rh(6)),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: r.sp(13), color: AppColors.muted)),
        Flexible(child: Text(value, style: GoogleFonts.inter(fontSize: r.sp(13), fontWeight: FontWeight.w500, color: AppColors.ink), textAlign: TextAlign.right)),
      ],
    ),
  );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  final Color? textColor;
  final String? trailing;
  const _SettingsTile({required this.icon, required this.color, required this.label, required this.onTap, this.textColor, this.trailing});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: r.rs(36),
        height: r.rh(36),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(r.rs(10))),
        child: Icon(icon, color: color, size: r.sp(20)),
      ),
      title: Text(label, style: GoogleFonts.inter(fontSize: r.sp(14), fontWeight: FontWeight.w500, color: textColor ?? AppColors.ink)),
      trailing: trailing != null
          ? Text(trailing!, style: GoogleFonts.inter(fontSize: r.sp(13), color: AppColors.muted))
          : (textColor != null ? null : Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: r.sp(20))),
    );
  }
}
