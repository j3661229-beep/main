import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/agri_ui.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/services/api_service.dart';
import '../../core/utils/responsive.dart';

class FpoBulkScreen extends ConsumerStatefulWidget {
  const FpoBulkScreen({super.key});

  @override
  ConsumerState<FpoBulkScreen> createState() => _FpoBulkScreenState();
}

class _FpoBulkScreenState extends ConsumerState<FpoBulkScreen> {
  final _qtyCtrl = TextEditingController();
  String? _crop;
  bool _loading = false;
  bool _submitted = false;

  Future<void> _submit() async {
    if (_crop == null || _qtyCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      final user = ref.read(authProvider).user;
      await ApiService.instance.submitFpoInterest({
        'cropName': _crop,
        'approxQuintals': double.tryParse(_qtyCtrl.text) ?? 0,
        'district': user?.effectiveDistrict,
        'village': user?.farmer?['village'],
      });
      setState(() => _submitted = true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    if (_submitted) {
      return AgriScreen(
        title: 'FPO Bulk Sell',
        subtitle: 'Interest registered',
        emoji: '✅',
        showBack: true,
        body: Padding(
          padding: EdgeInsets.all(r.rs(32)),
          child: Column(
            children: [
              SizedBox(height: r.rh(40)),
              AgriCard(
                child: Column(
                  children: [
                    Text('🎉', style: TextStyle(fontSize: r.sp(56))),
                    SizedBox(height: r.rh(16)),
                    Text('Interest registered!', style: GoogleFonts.spaceGrotesk(fontSize: r.sp(22), fontWeight: FontWeight.w800)),
                    SizedBox(height: r.rh(8)),
                    Text(
                      'We\'ll connect you with nearby FPOs and dealers for better bulk rates.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: AppColors.muted, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AgriScreen(
      title: 'FPO Bulk Selling',
      subtitle: 'Pool produce with farmers',
      emoji: '👥',
      accent: AppColors.dealerAccent,
      gradient: AppColors.dealerGradient,
      body: Padding(
        padding: EdgeInsets.fromLTRB(r.horizontalPadding, 20, r.horizontalPadding, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const InfoBanner(
              text: 'Pool your produce with other farmers for stronger negotiating power with dealers.',
              accent: AppColors.dealerAccent,
              tint: AppColors.dealerTint,
              icon: Icons.groups_outlined,
            ),
            SizedBox(height: r.rh(20)),
            AgriCard(
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _crop,
                    decoration: const InputDecoration(labelText: 'Crop to pool', border: InputBorder.none),
                    items: AppConstants.popularCrops
                        .map((c) => DropdownMenuItem(value: c['name'], child: Text('${c['emoji']} ${c['name']}')))
                        .toList(),
                    onChanged: (v) => setState(() => _crop = v),
                  ),
                  Divider(height: r.rh(1)),
                  TextField(
                    controller: _qtyCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    decoration: const InputDecoration(labelText: 'Your quantity (quintals)', suffixText: 'qtl', border: InputBorder.none),
                  ),
                ],
              ),
            ),
            SizedBox(height: r.rh(24)),
            AppButton(label: 'Register Interest', onTap: _submit, isLoading: _loading, color: AppColors.dealerAccent),
          ],
        ),
      ),
    );
  }
}
