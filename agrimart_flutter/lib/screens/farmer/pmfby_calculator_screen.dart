import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/agri_ui.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../core/utils/responsive.dart';

class PmfbyCalculatorScreen extends StatefulWidget {
  const PmfbyCalculatorScreen({super.key});

  @override
  State<PmfbyCalculatorScreen> createState() => _PmfbyCalculatorScreenState();
}

class _PmfbyCalculatorScreenState extends State<PmfbyCalculatorScreen> {
  final _areaCtrl = TextEditingController(text: '1');
  final _sumInsuredCtrl = TextEditingController(text: '40000');
  String _crop = 'Onion';
  String _season = 'Kharif';
  double? _premium;

  static const _crops = ['Onion', 'Tomato', 'Wheat', 'Soybean', 'Cotton', 'Grapes', 'Maize'];
  static const _seasons = ['Kharif', 'Rabi', 'Summer'];

  double _rateForCrop(String crop, String season) {
    final c = crop.toLowerCase();
    if (c.contains('onion') || c.contains('tomato')) return season == 'Kharif' ? 0.05 : 0.055;
    if (c.contains('wheat')) return 0.015;
    if (c.contains('cotton')) return 0.05;
    return 0.02;
  }

  void _calculate() {
    final area = double.tryParse(_areaCtrl.text) ?? 0;
    final sumInsured = double.tryParse(_sumInsuredCtrl.text) ?? 0;
    setState(() => _premium = sumInsured * area * _rateForCrop(_crop, _season));
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return AgriScreen(
      title: 'PMFBY Calculator',
      subtitle: 'Crop insurance premium',
      emoji: '🛡️',
      gradient: const LinearGradient(
        colors: [Color(0xFF6B3A10), Color(0xFFA85C1A), Color(0xFFD4793A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      accent: AppColors.dealerAccent,
      body: Padding(
        padding: EdgeInsets.fromLTRB(r.horizontalPadding, 20, r.horizontalPadding, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const InfoBanner(
              text: 'Estimate your PMFBY premium. Actual rates vary by district and notified crops.',
              accent: AppColors.dealerAccent,
              tint: AppColors.dealerTint,
              icon: Icons.shield_outlined,
            ),
            const SizedBox(height: 20),
            AgriCard(
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _crop,
                    decoration: const InputDecoration(labelText: 'Crop', border: InputBorder.none),
                    items: _crops.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _crop = v ?? _crop),
                  ),
                  const Divider(height: 1),
                  DropdownButtonFormField<String>(
                    value: _season,
                    decoration: const InputDecoration(labelText: 'Season', border: InputBorder.none),
                    items: _seasons.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => _season = v ?? _season),
                  ),
                  const Divider(height: 1),
                  TextField(
                    controller: _areaCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    decoration: const InputDecoration(labelText: 'Insured area (hectares)', border: InputBorder.none),
                  ),
                  const Divider(height: 1),
                  TextField(
                    controller: _sumInsuredCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Sum insured per hectare (₹)', prefixText: '₹ ', border: InputBorder.none),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppButton(label: 'Calculate Premium', onTap: _calculate, color: AppColors.dealerAccent),
            if (_premium != null) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.dealerTint, AppColors.dealerTint.withValues(alpha: 0.4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.dealerAccent.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Text('Estimated farmer premium', style: GoogleFonts.inter(color: AppColors.muted)),
                    const SizedBox(height: 8),
                    Text('₹${_premium!.toStringAsFixed(0)}', style: GoogleFonts.spaceGrotesk(fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.dealerAccent)),
                    const SizedBox(height: 12),
                    Text('Apply on pmfby.gov.in • Keep field photos for claims', style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
