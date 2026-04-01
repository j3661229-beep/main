import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import '../../data/services/api_service.dart';
import '../../data/providers/auth_provider.dart';
import '../../core/providers/locale_provider.dart';
import 'package:agrimart/l10n/app_localizations.dart';
import '../../services/voice_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class CropAdvisorScreen extends ConsumerStatefulWidget {
  const CropAdvisorScreen({super.key});

  @override
  ConsumerState<CropAdvisorScreen> createState() => _CropAdvisorState();
}

class _CropAdvisorState extends ConsumerState<CropAdvisorScreen> {
  late final _locCtrl = TextEditingController(text: ref.read(authProvider).user?.farmer?['district'] ?? 'Nashik');
  final _soilCtrl = TextEditingController(text: 'Black Cotton Soil');
  final _seasonCtrl = TextEditingController(text: 'Kharif');
  final _sizeCtrl = TextEditingController(text: '2');
  bool _loading = false;
  List _recommendations = [];

  Future<void> _analyze() async {
    setState(() => _loading = true);
    try {
      final locale = ref.read(localeProvider);
      final langName = locale.languageCode == 'hi' ? 'Hindi' : locale.languageCode == 'mr' ? 'Marathi' : 'English';
      final res = await ApiService.instance.getCropRecommend({
        'location': _locCtrl.text,
        'soilType': _soilCtrl.text,
        'season': _seasonCtrl.text,
        'farmSize': int.tryParse(_sizeCtrl.text) ?? 2,
        'language': langName,
      });
      setState(() => _recommendations = res['crops'] ?? []);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('AI Error: $e'), backgroundColor: AppColors.error));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _locCtrl.dispose();
    _soilCtrl.dispose();
    _seasonCtrl.dispose();
    _sizeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
          title: Text('🌱 ${l10n.cropAdvisor}'),
          backgroundColor: AppColors.primary),
      body: _recommendations.isNotEmpty
          ? _buildResults()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                            gradient: AppColors.heroGradient,
                            borderRadius: BorderRadius.circular(20)),
                        child: Row(children: [
                          const Text('🌾', style: TextStyle(fontSize: 48)),
                          const SizedBox(width: 16),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                const Text('Gemini AI Advisor',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(
                                    'Tell us about your farm setup and our AI will recommend the top high-yield crops.',
                                    style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.9),
                                        fontSize: 13))
                              ]))
                        ])),
                    const SizedBox(height: 28),
                    Text(l10n.farmDetails, style: AppTextStyles.headingMD),
                    const SizedBox(height: 16),
                    _buildField(
                        '${l10n.location} / District', _locCtrl, 'e.g. Pune, Nashik'),
                    const SizedBox(height: 14),
                    _buildField(
                        l10n.soilType, _soilCtrl, 'e.g. Black, Red, Sandy'),
                    const SizedBox(height: 14),
                    _buildField(l10n.season, _seasonCtrl, 'Kharif, Rabi or Zaid'),
                    const SizedBox(height: 14),
                    _buildField('${l10n.farmSize} (Acres)', _sizeCtrl,
                        'Enter farm size in acres',
                        isNum: true),
                    const SizedBox(height: 40),
                    SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _analyze,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                          ),
                          child: _loading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 3))
                              : Text(l10n.getAiRecommendations,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                        )),
                    const SizedBox(height: 40),
                  ]),
            ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, String hint,
      {bool isNum = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                AppTextStyles.labelLG.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          keyboardType: isNum ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border)),
          ),
        ),
      ],
    );
  }

  Widget _buildResults() {
    return Column(children: [
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.border))),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('AI Top Recommendations',
                style: AppTextStyles.headingSM),
            TextButton.icon(
                onPressed: () => setState(() => _recommendations = []),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('New Analysis',
                    style: TextStyle(fontWeight: FontWeight.bold)))
          ])),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: _recommendations.length,
          itemBuilder: (ctx, i) {
            final crop = _recommendations[i];
            return FadeInUp(
              delay: Duration(milliseconds: i * 100),
              duration: const Duration(milliseconds: 600),
              child: Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.white, Color(0xFFF8FAFC)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.1), width: 2),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 8))
                  ]
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            height: 70, width: 70,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]
                            ),
                            alignment: Alignment.center,
                            child: Text(crop['emoji'] ?? '🌿', style: const TextStyle(fontSize: 36)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(crop['crop'] ?? 'Unknown', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                                    IconButton(
                                      icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 24),
                                      onPressed: () {
                                        VoiceService.instance.speak("${crop['crop']}. ${crop['reason']}", languageCode: ref.read(localeProvider).languageCode);
                                      },
                                    )
                                  ]
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: (crop['matchPercent'] ?? 0) / 100.0,
                                          backgroundColor: AppColors.border,
                                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                          minHeight: 6,
                                        ),
                                      )
                                    ),
                                    const SizedBox(width: 12),
                                    Text('${crop['matchPercent']}% Match', style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w900, fontSize: 12)),
                                  ]
                                )
                              ]
                            )
                          )
                        ]
                      )
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface.withValues(alpha: 0.5),
                        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24))
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('💡', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Expanded(child: Text(crop['reason'] ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4, fontWeight: FontWeight.w500))),
                            ]
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _statInfo('Exp. Yield', crop['expectedYield']?.toString() ?? 'N/A', icon: '🧺'),
                              Container(height: 30, width: 1, color: AppColors.border),
                              _statInfo('Market Demand', (crop['marketDemand']?.toString() ?? 'Medium').toUpperCase(), icon: '📈'),
                            ]
                          )
                        ]
                      )
                    )
                  ]
                )
              ),
            );
          },
        ),
      ),
    ]);
  }

  Widget _statInfo(String label, String val, {required String icon}) =>
      Row(children: [
        Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]),
            child: Text(icon, style: const TextStyle(fontSize: 14))),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.bold)),
          Text(val,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark))
        ])
      ]);
}
