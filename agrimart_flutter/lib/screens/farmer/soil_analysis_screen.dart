import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:animate_do/animate_do.dart';
import '../../data/services/api_service.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/auth_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../services/voice_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shimmer.dart';

class SoilAnalysisScreen extends ConsumerStatefulWidget {
  const SoilAnalysisScreen({super.key});
  @override
  ConsumerState<SoilAnalysisScreen> createState() => _SoilAnalysisScreenState();
}

class _SoilAnalysisScreenState extends ConsumerState<SoilAnalysisScreen> {
  File? _image;
  Map? _result;
  bool _analyzing = false;

  Future<void> _pickImage(ImageSource src) async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: src, imageQuality: 85, maxWidth: 1200);
    if (picked != null) setState(() => _image = File(picked.path));
  }

  Future<void> _analyze() async {
    if (_image == null) return;
    setState(() {
      _analyzing = true;
      _result = null;
    });
    try {
      final user = ref.read(authProvider).user;
      final locale = ref.read(localeProvider);
      final language = locale.languageCode == 'hi' ? 'Hindi' : locale.languageCode == 'mr' ? 'Marathi' : 'English';
      final location = "${user?.farmer?['village'] ?? ''}, ${user?.farmer?['district'] ?? ''}";
      final res = await ApiService.instance.analyzeSoil(_image!.path, location: location, language: language);
      setState(() {
        _result = res;
        _analyzing = false;
      });
    } catch (e) {
      setState(() => _analyzing = false);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Analysis failed: $e'),
            backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
          title: Text('🧪 ${l10n.soilAnalysis}'),
          backgroundColor: AppColors.primary),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            // Info banner
            Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primaryBorder)),
                child: const Row(children: [
                  const Text('🤖', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(l10n.soilAnalysis,
                            style: AppTextStyles.headingSM),
                        const Text(
                            'Take a photo of your soil to get instant analysis and crop recommendations powered by AI.',
                            style: AppTextStyles.bodySM),
                      ]))
                ])),

            const SizedBox(height: 24),

            // Image picker
            GestureDetector(
              onTap: () => showModalBottomSheet(
                  context: context,
                  builder: (_) => SafeArea(
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                        ListTile(
                            leading: const Text('📷',
                                style: TextStyle(fontSize: 24)),
                            title: const Text('Take Photo'),
                            onTap: () {
                              Navigator.pop(context);
                              _pickImage(ImageSource.camera);
                            }),
                        ListTile(
                            leading: const Text('🖼️',
                                style: TextStyle(fontSize: 24)),
                            title: const Text('Choose from Gallery'),
                            onTap: () {
                              Navigator.pop(context);
                              _pickImage(ImageSource.gallery);
                            }),
                      ]))),
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color:
                          _image != null ? AppColors.primary : AppColors.border,
                      width: _image != null ? 2 : 1,
                      style: BorderStyle.solid),
                ),
                child: _image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(_image!, fit: BoxFit.cover))
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            Text('🟫', style: TextStyle(fontSize: 48)),
                            SizedBox(height: 8),
                            Text('Tap to take soil photo',
                                style: AppTextStyles.bodySM)
                          ]),
              ),
            ),

            const SizedBox(height: 16),

            if (_image != null)
              Row(children: [
                Expanded(
                    child: OutlinedButton.icon(
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Retake'),
                        onPressed: () => _pickImage(ImageSource.camera))),
                const SizedBox(width: 12),
                Expanded(
                    child: ElevatedButton.icon(
                        icon: const Icon(Icons.science_outlined),
                        label: Text(l10n.soilAnalysis),
                        onPressed: _analyzing ? null : _analyze)),
              ]),

            if (_analyzing) ...[
              const SizedBox(height: 24),
              Column(children: [
                const AppShimmerCard(),
                const SizedBox(height: 12),
                const AppShimmer(width: double.infinity, height: 40),
                const SizedBox(height: 20),
                const Text('🔍 AI is analyzing your soil…',
                    style: AppTextStyles.headingSM),
                Text('This takes about 5-10 seconds',
                    style: AppTextStyles.bodyXS
                        .copyWith(color: AppColors.textTertiary)),
              ]),
            ],

            if (_result != null) ...[
              const SizedBox(height: 24),
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, AppColors.primarySurface.withValues(alpha: 0.5)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _PremiumBadge('🟫', 'Soil Type', _result!['analysis']?['soilType'] ?? 'N/A', AppColors.amber),
                          const SizedBox(width: 16),
                          _PremiumBadge('⚗️', 'pH Level', '${_result!['analysis']?['phLevel'] ?? 'N/A'}', AppColors.primary),
                        ],
                      ),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(color: AppColors.primaryBorder)),
                      _NPKMeter('Nitrogen (N)', '${_result!['analysis']?['nitrogenLevel'] ?? 'N/A'}', '🌿', const Color(0xFF4CAF50)),
                      _NPKMeter('Phosphorus (P)', '${_result!['analysis']?['phosphorusLevel'] ?? 'N/A'}', '🔵', const Color(0xFF2196F3)),
                      _NPKMeter('Potassium (K)', '${_result!['analysis']?['potassiumLevel'] ?? 'N/A'}', '🟡', const Color(0xFFFFC107)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_result!['analysis']?['treatmentAdvice'] != null)
                FadeInUp(
                  duration: const Duration(milliseconds: 700),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: AppColors.primaryDark,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryDark.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          )
                        ]),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                                    child: const Text('✨', style: TextStyle(fontSize: 16)),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text('AI Advisory', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.volume_up_rounded, color: Colors.white),
                                onPressed: () {
                                  final advice = _result!['analysis']?['treatmentAdvice'];
                                  final crops = (_result!['analysis']?['recommendedCrops'] as List? ?? []).join(', ');
                                  VoiceService.instance.speak("$advice. Recommended crops for your area are: $crops", 
                                      languageCode: ref.read(localeProvider).languageCode);
                                },
                              )
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(_result!['analysis']?['treatmentAdvice'].toString() ?? '',
                              style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 20),
                          const Text('RECOMMENDED CROPS', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: (_result!['analysis']?['recommendedCrops'] as List? ?? []).map((c) => 
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(c, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
                              )
                            ).toList(),
                          )
                        ]),
                  ),
                ),
            ],
          ])),
    );
  }
}

class _PremiumBadge extends StatelessWidget {
  final String emoji, label, value;
  final Color color;
  const _PremiumBadge(this.emoji, this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textTertiary)),
            ]),
            const SizedBox(height: 8),
            Text(value, style: AppTextStyles.headingMD.copyWith(color: AppColors.textPrimary, height: 1.1)),
          ],
        ),
      ),
    );
  }
}

class _NPKMeter extends StatelessWidget {
  final String label, value, emoji;
  final Color color;
  const _NPKMeter(this.label, this.value, this.emoji, this.color);

  @override
  Widget build(BuildContext context) {
    double progress = 0.5;
    final v = value.toLowerCase();
    if (v.contains('high')) progress = 0.9;
    if (v.contains('low')) progress = 0.2;
    if (v.contains('good') || v.contains('optimal')) progress = 0.8;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                   Text(emoji, style: const TextStyle(fontSize: 16)),
                   const SizedBox(width: 8),
                   Text(label, style: AppTextStyles.bodyMD.copyWith(fontWeight: FontWeight.w800, color: AppColors.textSecondary)),
                ]
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(value.toUpperCase(), style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(color: AppColors.border.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(4)),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.fastOutSlowIn,
                    height: 8,
                    width: constraints.maxWidth * progress,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [color.withValues(alpha: 0.5), color]),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                  );
                }
              )
            ],
          )
        ],
      )
    );
  }
}
