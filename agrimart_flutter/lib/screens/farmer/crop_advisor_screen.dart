import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import '../../data/services/api_service.dart';
import '../../data/providers/auth_provider.dart';
import '../../core/providers/app_language_provider.dart';
import '../../core/providers/locale_provider.dart';
import 'package:agrimart/l10n/app_localizations.dart';
import '../../services/voice_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/farm_profile_utils.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/widgets/ai_analysis_progress.dart';
import '../../core/utils/responsive.dart';

class CropAdvisorScreen extends ConsumerStatefulWidget {
  const CropAdvisorScreen({super.key});

  @override
  ConsumerState<CropAdvisorScreen> createState() => _CropAdvisorState();
}

class _CropAdvisorState extends ConsumerState<CropAdvisorScreen> {
  final _seasonCtrl = TextEditingController(text: 'Kharif');
  bool _loading = false;
  List _recommendations = [];

  String _t(String en, String hi, String mr) {
    final code = ref.read(localeProvider).languageCode;
    if (code == 'hi') return hi;
    if (code == 'mr') return mr;
    return en;
  }

  @override
  void initState() {
    super.initState();
    final month = DateTime.now().month;
    _seasonCtrl.text = month >= 6 && month <= 9 ? 'Kharif' : 'Rabi';
  }

  Future<void> _analyze() async {
    setState(() => _loading = true);
    try {
      final langName = ref.read(appLanguageProvider).aiName;
      final res = await ApiService.instance.getCropRecommend({
        'season': _seasonCtrl.text.trim(),
        'language': langName,
      });
      setState(() => _recommendations = res['crops'] ?? []);
      if (_recommendations.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_t('No recommendations returned. Try again.', 'कोई सुझाव नहीं।', 'शिफारसी मिळाल्या नाहीत.')),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      if (isRequestCancelled(e)) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(extractUserFacingError(e)), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _cancelAnalysis() {
    ApiService.instance.cancelAiRequest();
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    ApiService.instance.cancelAiRequest();
    _seasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authProvider).user;
    final farmer = user?.farmer as Map?;
    final location = [
      farmer?['village'],
      farmer?['taluka'],
      user?.effectiveDistrict ?? farmer?['district'],
    ].where((e) => e != null && e.toString().isNotEmpty).join(', ');
    final crops = FarmProfileUtils.cropsDisplay(farmer);
    final acres = FarmProfileUtils.farmSizeDisplay(farmer);
    final soil = farmer?['soilType']?.toString() ?? '—';
    final water = farmer?['waterSource']?.toString() ?? '—';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
          title: Text('🌱 ${l10n.cropAdvisor}'),
          backgroundColor: AppColors.primary),
      body: _recommendations.isNotEmpty
          ? _buildResults()
          : SingleChildScrollView(
              padding: EdgeInsets.all(r.rs(24)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        padding: EdgeInsets.all(r.rs(20)),
                        decoration: BoxDecoration(
                            gradient: AppColors.heroGradient,
                            borderRadius: BorderRadius.circular(r.rs(20))),
                        child: Row(children: [
                          Text('🌾', style: TextStyle(fontSize: r.sp(48))),
                          SizedBox(width: r.rs(16)),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                  Text(l10n.cropAdvisor,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: r.sp(20),
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: r.rh(4)),
                                Text(
                                    _t(
                                      'Recommendations based on your saved farm profile',
                                      'आपके खेत प्रोफ़ाइल पर आधारित सुझाव',
                                      'तुमच्या शेत प्रोफाइलवर आधारित शिफारसी',
                                    ),
                                    style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.9),
                                        fontSize: r.sp(13)))
                              ]))
                        ])),
                    SizedBox(height: r.rh(20)),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(r.rs(16)),
                      decoration: BoxDecoration(
                        color: AppColors.farmerTint,
                        borderRadius: BorderRadius.circular(r.rs(16)),
                        border: Border.all(color: AppColors.primaryBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _t('Your farm', 'आपका खेत', 'तुमचे शेत'),
                            style: AppTextStyles.labelLG.copyWith(color: AppColors.farmerAccent, fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: r.rh(10)),
                          _profileRow(Icons.location_on_rounded, location.isEmpty ? '—' : location),
                          _profileRow(Icons.grass_rounded, crops),
                          _profileRow(Icons.square_foot_rounded, '$acres acres'),
                          _profileRow(Icons.landslide_rounded, soil),
                          _profileRow(Icons.water_drop_rounded, water),
                        ],
                      ),
                    ),
                    SizedBox(height: r.rh(24)),
                    Text(l10n.season, style: AppTextStyles.headingMD),
                    SizedBox(height: r.rh(8)),
                    Text(
                      _t('Choose season for recommendations', 'सुझाव के लिए मौसम चुनें', 'शिफारसीसाठी हंगाम निवडा'),
                      style: AppTextStyles.labelLG.copyWith(color: AppColors.textSecondary),
                    ),
                    SizedBox(height: r.rh(12)),
                    _buildField(l10n.season, _seasonCtrl, 'Kharif, Rabi or Zaid'),
                    SizedBox(height: r.rh(32)),
                    SizedBox(
                        width: double.infinity,
                        height: r.rh(56),
                        child: ElevatedButton(
                          onPressed: _loading ? null : _analyze,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(r.rs(16))),
                            elevation: 4,
                          ),
                          child: _loading
                              ? SizedBox(height: r.rh(24),
                                  width: r.rs(24),
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: r.rs(3)))
                              : Text(l10n.getAiRecommendations,
                                  style: TextStyle(
                                      fontSize: r.sp(16),
                                      fontWeight: FontWeight.bold)),
                        )),
                    if (_loading) ...[
                      SizedBox(height: r.rh(20)),
                      AiAnalysisProgressCard(
                        title: _t('Analyzing…', 'विश्लेषण…', 'विश्लेषण…'),
                        subtitle: _t(
                          'Finding best crops for your farm profile',
                          'आपके खेत के लिए सर्वोत्तम फसलें खोज रहे हैं',
                          'तुमच्या शेतासाठी सर्वोत्तम पिके शोधत आहोत',
                        ),
                        cancelLabel: l10n.cancel,
                        onCancel: _cancelAnalysis,
                        accentColor: AppColors.primary,
                      ),
                    ],
                    SizedBox(height: r.rh(40)),
                  ]),
            ),
    );
  }

  Widget _profileRow(IconData icon, String value) {
    final r = context.r;
    return Padding(
      padding: EdgeInsets.only(bottom: r.rh(6)),
      child: Row(
        children: [
          Icon(icon, size: r.sp(16), color: AppColors.muted),
          SizedBox(width: r.rs(8)),
          Expanded(child: Text(value, style: AppTextStyles.bodyMD)),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, String hint,
      {bool isNum = false, Widget? suffix}) {
    final r = context.r;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                AppTextStyles.labelLG.copyWith(color: AppColors.textSecondary)),
        SizedBox(height: r.rh(8)),
        TextFormField(
          controller: ctrl,
          keyboardType: isNum ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(r.rs(14)),
                borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(r.rs(14)),
                borderSide: const BorderSide(color: AppColors.border)),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }

  Widget _buildResults() {
    final r = context.r;
    return Column(children: [
      Container(
          padding: EdgeInsets.symmetric(horizontal: r.rs(20), vertical: r.rh(16)),
          decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.border))),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('AI Top Recommendations',
                style: AppTextStyles.headingSM),
            TextButton.icon(
                onPressed: () => setState(() => _recommendations = []),
                icon: Icon(Icons.refresh, size: r.sp(18)),
                label: const Text('New Analysis',
                    style: TextStyle(fontWeight: FontWeight.bold)))
          ])),
      Expanded(
        child: ListView.builder(
          padding: EdgeInsets.all(r.rs(20)),
          itemCount: _recommendations.length,
          itemBuilder: (ctx, i) {
            final crop = _recommendations[i];
            return FadeInUp(
              delay: Duration(milliseconds: i * 100),
              duration: const Duration(milliseconds: 600),
              child: Container(
                margin: EdgeInsets.only(bottom: r.rh(20)),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.white, Color(0xFFF8FAFC)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(r.rs(24)),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.1), width: 2),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.05), blurRadius: r.rs(20), offset: Offset(0, 8))
                  ]
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(r.rs(20)),
                      child: Row(
                        children: [
                          Container(
                            height: r.rh(70), width: 70,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                              borderRadius: BorderRadius.circular(r.rs(20)),
                              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: r.rs(10), offset: Offset(0, 4))]
                            ),
                            alignment: Alignment.center,
                            child: Text(crop['emoji'] ?? '🌿', style: TextStyle(fontSize: r.sp(36))),
                          ),
                          SizedBox(width: r.rs(16)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(crop['crop'] ?? 'Unknown', style: TextStyle(fontSize: r.sp(22), fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                                    IconButton(
                                      icon: Icon(Icons.volume_up_rounded, color: AppColors.primary, size: r.sp(24)),
                                      onPressed: () {
                                        VoiceService.instance.speak("${crop['crop']}. ${crop['reason']}", languageCode: ref.read(localeProvider).languageCode);
                                      },
                                    )
                                  ]
                                ),
                                SizedBox(height: r.rh(8)),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(r.rs(4)),
                                        child: LinearProgressIndicator(
                                          value: (crop['matchPercent'] ?? 0) / 100.0,
                                          backgroundColor: AppColors.border,
                                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                          minHeight: r.rh(6),
                                        ),
                                      )
                                    ),
                                    SizedBox(width: r.rs(12)),
                                    Text('${crop['matchPercent']}% Match', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w900, fontSize: r.sp(12))),
                                  ]
                                )
                              ]
                            )
                          )
                        ]
                      )
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: r.rs(20), vertical: r.rh(16)),
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
                              Text('💡', style: TextStyle(fontSize: context.r.sp(16))),
                              SizedBox(width: r.rs(8)),
                              Expanded(child: Text(crop['reason'] ?? '', style: TextStyle(fontSize: r.sp(13), color: AppColors.textSecondary, height: 1.4, fontWeight: FontWeight.w500))),
                            ]
                          ),
                          SizedBox(height: r.rh(16)),
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

  Widget _statInfo(String label, String val, {required String icon}) {
    final r = context.r;
    return Row(children: [
        Container(
            padding: EdgeInsets.all(r.rs(8)),
            decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: r.rs(4))]),
            child: Text(icon, style: TextStyle(fontSize: r.sp(14)))),
        SizedBox(width: r.rs(8)),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  fontSize: r.sp(10),
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.bold)),
          Text(val,
              style: TextStyle(
                  fontSize: r.sp(13),
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark))
        ])
      ]);
  }
}

