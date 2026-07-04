import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/services/api_service.dart';

final _diagnoseHistoryProvider = FutureProvider<List>((ref) async {
  return ApiService.instance.getDiagnoseHistory();
});

class CropDoctorScreen extends ConsumerStatefulWidget {
  const CropDoctorScreen({super.key});
  @override
  ConsumerState<CropDoctorScreen> createState() => _CropDoctorScreenState();
}

class _CropDoctorScreenState extends ConsumerState<CropDoctorScreen> {
  File? _image;
  bool _isAnalyzing = false;
  Map? _result;
  String? _error;

  Future<void> _pickImage(ImageSource src) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: src, imageQuality: 85);
    if (picked == null) return;
    setState(() { _image = File(picked.path); _result = null; _error = null; });
    await _analyze();
  }

  Future<void> _analyze() async {
    if (_image == null) return;
    setState(() { _isAnalyzing = true; _error = null; });
    try {
      final res = await ApiService.instance.diagnoseCrop(_image!.path);
      setState(() { _result = res; _isAnalyzing = false; });
      ref.invalidate(_diagnoseHistoryProvider);
    } catch (e) {
      setState(() { _error = 'Analysis failed. Please try again.'; _isAnalyzing = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(_diagnoseHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: GestureDetector(onTap: () => context.pop(), child: const Icon(Icons.arrow_back_rounded)),
        title: Text('Crop Doctor', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w700)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: AppColors.farmerTint, borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              const Icon(Icons.auto_awesome, color: AppColors.farmerAccent, size: 14),
              const SizedBox(width: 4),
              Text('AI Powered', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.farmerAccent)),
            ]),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.farmerAccent,
        onRefresh: () async => ref.invalidate(_diagnoseHistoryProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Image Picker Card ─────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppColors.softShadow,
                ),
                child: Column(
                  children: [
                    if (_image == null) ...[
                      Container(
                        width: double.infinity,
                        height: 180,
                        decoration: BoxDecoration(
                          color: AppColors.farmerTint,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.farmerAccent.withValues(alpha: 0.3), style: BorderStyle.solid, width: 2),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🌿', style: TextStyle(fontSize: 52)),
                            const SizedBox(height: 12),
                            Text('Take a photo of your crop', style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.farmerAccent)),
                            const SizedBox(height: 4),
                            Text('AI will identify disease & suggest treatment', style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
                          ],
                        ),
                      ),
                    ] else ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_image!, height: 220, width: double.infinity, fit: BoxFit.cover),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'Camera',
                            onTap: () => _pickImage(ImageSource.camera),
                            color: AppColors.farmerAccent,
                            icon: Icons.camera_alt_outlined,
                            height: 46,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppButton(
                            label: 'Gallery',
                            onTap: () => _pickImage(ImageSource.gallery),
                            isOutlined: true,
                            color: AppColors.farmerAccent,
                            icon: Icons.photo_library_outlined,
                            height: 46,
                          ),
                        ),
                      ],
                    ),
                    if (_image != null && !_isAnalyzing && _result == null) ...[
                      const SizedBox(height: 12),
                      AppButton(label: 'Analyze Crop', onTap: _analyze, color: AppColors.farmerAccent, icon: Icons.search_rounded),
                    ],
                  ],
                ),
              ),

              // ── Analyzing loader ──────────────────────────────
              if (_isAnalyzing) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.softShadow),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40, height: 40,
                        child: CircularProgressIndicator(
                          color: AppColors.farmerAccent,
                          strokeWidth: 3,
                          backgroundColor: AppColors.farmerTint,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Analyzing crop...', style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink)),
                            Text('Gemini Vision AI is working', style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ── Error ─────────────────────────────────────────
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.dangerTint, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.danger),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_error!, style: GoogleFonts.inter(color: AppColors.danger))),
                    ],
                  ),
                ),
              ],

              // ── Result Card ───────────────────────────────────
              if (_result != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.farmerAccent.withValues(alpha: 0.3)),
                    boxShadow: AppColors.softShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.farmerTint, borderRadius: BorderRadius.circular(12)), child: const Center(child: Text('🔬', style: TextStyle(fontSize: 20)))),
                          const SizedBox(width: 12),
                          Text('Analysis Result', style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _ResultRow(label: 'Crop', value: _result!['crop'] ?? 'Unknown'),
                      _ResultRow(label: 'Detected Issue', value: _result!['issue'] ?? _result!['disease'] ?? 'None'),
                      _ResultRow(
                        label: 'Confidence',
                        value: '${_result!['confidence'] ?? 0}%',
                        valueColor: AppColors.success,
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 12),
                      Text('Treatment Recommendation', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.successTint, borderRadius: BorderRadius.circular(12)),
                        child: Text(
                          _result!['treatment'] ?? _result!['recommendation'] ?? 'No treatment recommendation available.',
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.success, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ── History ───────────────────────────────────────
              const SizedBox(height: 28),
              Text('Scan History', style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
              const SizedBox(height: 12),
              history.when(
                loading: () => const ShimmerBox(height: 100, radius: 12),
                error: (_, __) => Text('Could not load history', style: GoogleFonts.inter(color: AppColors.muted)),
                data: (list) {
                  if (list.isEmpty) return EmptyState(emoji: '🔬', title: 'No scans yet', subtitle: 'Scan a crop to see history here');
                  return Container(
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border), boxShadow: AppColors.softShadow),
                    child: Column(
                      children: List.generate(list.length, (i) {
                        final h = list[i];
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.farmerTint, borderRadius: BorderRadius.circular(10)), child: const Center(child: Text('🌿', style: TextStyle(fontSize: 18)))),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(h['crop'] ?? 'Unknown', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink)),
                                        Text(h['issue'] ?? h['disease'] ?? 'No issue', style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
                                      ],
                                    ),
                                  ),
                                  BadgeChip.status(h['confidence'] != null ? '${h['confidence']}%' : 'N/A'),
                                ],
                              ),
                            ),
                            if (i < list.length - 1) const Divider(height: 1, color: AppColors.border),
                          ],
                        );
                      }),
                    ),
                  );
                },
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _ResultRow({required this.label, required this.value, this.valueColor});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted)),
          Text(value, style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor ?? AppColors.ink)),
        ],
      ),
    );
  }
}

