import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../data/services/api_service.dart';
import '../../data/providers/auth_provider.dart';
import '../../services/voice_service.dart';
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
      final language = ref.read(languageProvider);
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
    return Scaffold(
      appBar: AppBar(
          title: const Text('🧪 Soil Analysis'),
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
                        Text('AI Soil Analysis',
                            style: AppTextStyles.headingSM),
                        Text(
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
                        label: const Text('Analyze Soil'),
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
                duration: const Duration(milliseconds: 500),
                child: Column(children: [
                   _ResultCard('Soil Type', _result!['analysis']?['soilType'] ?? 'N/A', '🟫'),
                   _ResultCard('pH Level', '${_result!['analysis']?['phLevel'] ?? 'N/A'}', '⚗️'),
                   _ResultCard('Nitrogen', '${_result!['analysis']?['nitrogenLevel'] ?? 'N/A'}', '🌿'),
                   _ResultCard('Phosphorus', '${_result!['analysis']?['phosphorusLevel'] ?? 'N/A'}', '🔵'),
                   _ResultCard('Potassium', '${_result!['analysis']?['potassiumLevel'] ?? 'N/A'}', '🟡'),
                ]),
              ),
              const SizedBox(height: 12),
              if (_result!['analysis']?['treatmentAdvice'] != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primaryBorder),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ]),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('🌱 AI Advice',
                                style: AppTextStyles.headingMD),
                            IconButton(
                              icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary),
                              onPressed: () {
                                final advice = _result!['analysis']?['treatmentAdvice'];
                                final crops = (_result!['analysis']?['recommendedCrops'] as List? ?? []).join(', ');
                                VoiceService.instance.speak("$advice. Recommended crops for your area are: $crops", 
                                    languageCode: ref.read(languageProvider));
                              },
                            )
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(_result!['analysis']?['treatmentAdvice'].toString() ?? '',
                            style: AppTextStyles.bodyMD),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: (_result!['analysis']?['recommendedCrops'] as List? ?? []).map((c) => 
                            Chip(label: Text(c, style: const TextStyle(fontSize: 12)), backgroundColor: Colors.white)
                          ).toList(),
                        )
                      ]),
                ),
            ],
          ])),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String key_, value, emoji;
  const _ResultCard(this.key_, this.value, this.emoji);
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border)),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(child: Text(key_, style: AppTextStyles.bodyMD)),
          Text(value,
              style:
                  AppTextStyles.headingSM.copyWith(color: AppColors.primary)),
        ]),
      );
}
