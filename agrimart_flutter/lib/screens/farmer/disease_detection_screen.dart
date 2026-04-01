import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:animate_do/animate_do.dart';
import '../../data/services/api_service.dart';
import '../../data/providers/auth_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../services/voice_service.dart';
import 'package:agrimart/l10n/app_localizations.dart';
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
      final locale = ref.read(localeProvider);
      final langName = locale.languageCode == 'hi' ? 'Hindi' : locale.languageCode == 'mr' ? 'Marathi' : 'English';
      final r = await ApiService.instance.detectDisease(_image!.path, language: langName);
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
          title: Text('🔬 ${l10n.diseaseDetection}'),
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
                        Text(l10n.diseaseDetection,
                            style: AppTextStyles.headingSM),
                        const Text(
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
                  label: Text(l10n.diseaseDetection),
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
              const SizedBox(height: 24),
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.shade50, Colors.white],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.red.shade100, width: 2),
                    boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.red.shade100, shape: BoxShape.circle),
                            child: const Text('🦠', style: TextStyle(fontSize: 32)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('DETECTED DISEASE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.red.shade800, letterSpacing: 1.5)),
                                const SizedBox(height: 4),
                                Text(_result!['analysis']?['diseaseName'] ?? 'Unknown', style: AppTextStyles.headingMD.copyWith(color: AppColors.textPrimary, height: 1.1)),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                                  child: Text('Severity: ${_result!['analysis']?['severity'] ?? 'Moderate'}', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w800, fontSize: 12)),
                                )
                              ]
                            )
                          )
                        ]
                      ),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider()),
                      _DiseaseDetailRow('Symptoms', (_result!['analysis']?['symptoms'] as List? ?? []).join(', '), '🤒'),
                      const SizedBox(height: 16),
                      _DiseaseDetailRow('Prevention', (_result!['analysis']?['preventionTips'] as List? ?? []).join('. '), '🛡️'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if ((_result!['analysis']?['treatments'] as List? ?? []).isNotEmpty)
                FadeInUp(
                  duration: const Duration(milliseconds: 700),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                        color: const Color(0xFF1E293B), // Premium dark theme for actions
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1E293B).withValues(alpha: 0.3),
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
                                    child: const Text('💊', style: TextStyle(fontSize: 16)),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text('Treatment Plan', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.volume_up_rounded, color: Colors.white),
                                onPressed: () {
                                  final name = _result!['analysis']?['diseaseName'];
                                  final treat = (_result!['analysis']?['treatments'] as List? ?? []).map((t) => t['name']).join(', ');
                                  final prev = (_result!['analysis']?['preventionTips'] as List? ?? []).join('. ');
                                  
                                  VoiceService.instance.speak("Detected: $name. Treatment includes $treat. Prevention: $prev", 
                                      languageCode: ref.read(localeProvider).languageCode);
                                },
                              )
                            ],
                          ),
                          const SizedBox(height: 20),
                          ...(_result!['analysis']?['treatments'] as List? ?? []).map((t) => 
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              child: Row(
                                children: [
                                  const Text('🧪', style: TextStyle(fontSize: 24)),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(t['name'], style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text('${t['dosage']} • ${t['application']}', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                                      ]
                                    )
                                  )
                                ]
                              )
                            )
                          ).toList(),
                        ]),
                  ),
                ),
            ],
          ])),
    );
  }
}

class _DiseaseDetailRow extends StatelessWidget {
  final String title, content, emoji;
  const _DiseaseDetailRow(this.title, this.content, this.emoji);

  @override
  Widget build(BuildContext context) {
    if (content.isEmpty) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
          child: Text(emoji, style: const TextStyle(fontSize: 16)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(content, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4, fontWeight: FontWeight.w500)),
            ]
          )
        )
      ]
    );
  }
}
