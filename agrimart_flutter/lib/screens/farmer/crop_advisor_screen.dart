import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import '../../data/services/api_service.dart';
import '../../data/providers/auth_provider.dart';
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
      final lang = ref.read(languageProvider);
      final res = await ApiService.instance.getCropRecommend({
        'location': _locCtrl.text,
        'soilType': _soilCtrl.text,
        'season': _seasonCtrl.text,
        'farmSize': int.tryParse(_sizeCtrl.text) ?? 2,
        'language': lang,
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
          title: const Text('🌱 AI Crop Advisor'),
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
                    const Text('Farm Details', style: AppTextStyles.headingMD),
                    const SizedBox(height: 16),
                    _buildField(
                        'Location / District', _locCtrl, 'e.g. Pune, Nashik'),
                    const SizedBox(height: 14),
                    _buildField(
                        'Soil Type', _soilCtrl, 'e.g. Black, Red, Sandy'),
                    const SizedBox(height: 14),
                    _buildField('Season', _seasonCtrl, 'Kharif, Rabi or Zaid'),
                    const SizedBox(height: 14),
                    _buildField('Farm Size (Acres)', _sizeCtrl,
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
                              : const Text('✨ Get AI Recommendations',
                                  style: TextStyle(
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
          padding: const EdgeInsets.all(16),
          itemCount: _recommendations.length,
          itemBuilder: (ctx, i) {
            final crop = _recommendations[i];
            return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ]),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(14)),
                            child: Text(crop['emoji'] ?? '🌿',
                                style: const TextStyle(fontSize: 32))),
                        const SizedBox(width: 16),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(crop['crop'] ?? 'Unknown',
                                      style: AppTextStyles.headingMD),
                                  IconButton(
                                    icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 20),
                                    onPressed: () {
                                       VoiceService.instance.speak("${crop['crop']}. ${crop['reason']}", 
                                           languageCode: ref.read(languageProvider));
                                    },
                                  )
                                ],
                              ),
                              const SizedBox(height: 4),
                              Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(20)),
                                  child: Text('${crop['matchPercent']}% Match',
                                      style: const TextStyle(
                                          color: AppColors.primaryDark,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11))),
                            ])),
                      ]),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      Text(crop['reason'] ?? '',
                          style: AppTextStyles.bodyMD
                              .copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 20),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _statInfo('Exp. Yield',
                                crop['expectedYield']?.toString() ?? 'N/A',
                                icon: '🧺'),
                            _statInfo(
                                'Market Demand',
                                (crop['marketDemand']?.toString() ?? 'Medium')
                                    .toUpperCase(),
                                icon: '📈'),
                          ]),
                    ]));
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
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8)),
            child: Text(icon, style: const TextStyle(fontSize: 16))),
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
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark))
        ])
      ]);
}
