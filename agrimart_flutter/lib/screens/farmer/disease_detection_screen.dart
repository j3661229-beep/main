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

class DiseaseDetectionScreen extends ConsumerStatefulWidget {
  const DiseaseDetectionScreen({super.key});
  @override
  ConsumerState<DiseaseDetectionScreen> createState() =>
      _DiseaseDetectionState();
}

class _DiseaseDetectionState extends ConsumerState<DiseaseDetectionScreen> {
  File? _image;
  Map? _result;
  bool _analyzing = false;

  Future<void> _pickImage(ImageSource src) async {
    final p = await ImagePicker()
        .pickImage(source: src, imageQuality: 85, maxWidth: 1200);
    if (p != null) setState(() => _image = File(p.path));
  }

  Future<void> _analyze() async {
    if (_image == null) return;
    setState(() {
      _analyzing = true;
      _result = null;
    });
    try {
      final lang = ref.read(languageProvider);
      final r = await ApiService.instance.detectDisease(_image!.path, language: lang);
      setState(() {
        _result = r;
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
          title: const Text('🔬 Disease Detection'),
          backgroundColor: AppColors.primary),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3))),
                child: const Row(children: [
                  Text('🔬', style: TextStyle(fontSize: 28)),
                  SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('AI Disease Detection',
                            style: AppTextStyles.headingSM),
                        Text(
                            'Photo of affected crop leaf/plant for AI disease identification and treatment recommendations.',
                            style: AppTextStyles.bodySM),
                      ]))
                ])),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => showModalBottomSheet(
                  context: context,
                  builder: (_) => SafeArea(
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                        ListTile(
                            leading: const Text('📷',
                                style: TextStyle(fontSize: 24)),
                            title: const Text('Camera'),
                            onTap: () {
                              Navigator.pop(context);
                              _pickImage(ImageSource.camera);
                            }),
                        ListTile(
                            leading: const Text('🖼️',
                                style: TextStyle(fontSize: 24)),
                            title: const Text('Gallery'),
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
                          color: _image != null
                              ? AppColors.primary
                              : AppColors.border,
                          width: _image != null ? 2 : 1)),
                  child: _image != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.file(_image!, fit: BoxFit.cover))
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                              Text('🌿', style: TextStyle(fontSize: 48)),
                              SizedBox(height: 8),
                              Text('Tap to capture affected plant',
                                  style: AppTextStyles.bodySM)
                            ])),
            ),
            const SizedBox(height: 16),
            if (_image != null)
              ElevatedButton.icon(
                  icon: const Icon(Icons.biotech),
                  label: const Text('Detect Disease'),
                  onPressed: _analyzing ? null : _analyze),
            if (_analyzing) ...[
              const SizedBox(height: 32),
              const AppShimmerCard(),
              const SizedBox(height: 12),
              const AppShimmer(width: 200, height: 16),
              const SizedBox(height: 24),
              const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 12),
                Text('🔍 Analyzing crop health…',
                    style: AppTextStyles.headingSM),
              ]),
            ],
            if (_result != null) ...[
              const SizedBox(height: 20),
              FadeInRight(
                duration: const Duration(milliseconds: 400),
                child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
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
                              Expanded(
                                child: Row(children: [
                                  const Text('⚠️', style: TextStyle(fontSize: 24)),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(_result!['analysis']?['diseaseName'] ?? 'Unknown',
                                        style: AppTextStyles.headingMD),
                                  )
                                ]),
                              ),
                              IconButton(
                                icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary),
                                onPressed: () {
                                  final name = _result!['analysis']?['diseaseName'];
                                  final treat = (_result!['analysis']?['treatments'] as List? ?? []).map((t) => t['name']).join(', ');
                                  final prev = (_result!['analysis']?['preventionTips'] as List? ?? []).join('. ');
                                  
                                  VoiceService.instance.speak("Detected: $name. Treatment includes $treat. Prevention: $prev", 
                                      languageCode: ref.read(languageProvider));
                                },
                              )
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Severity: ${_result!['analysis']?['severity'] ?? 'Moderate'}',
                              style: AppTextStyles.bodyMD.copyWith(color: AppColors.error, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          const Text('Symptoms:', style: AppTextStyles.headingSM),
                          Text((_result!['analysis']?['symptoms'] as List? ?? []).join(', '), style: AppTextStyles.bodyMD),
                          const SizedBox(height: 12),
                          const Text('Treatment & Application:', style: AppTextStyles.headingSM),
                          ...(_result!['analysis']?['treatments'] as List? ?? []).map((t) => 
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text('• ${t['name']}: ${t['dosage']} (${t['application']})', style: AppTextStyles.bodyMD),
                            )
                          ),
                        ])),
              ),
            ],
          ])),
    );
  }
}
