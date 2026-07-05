import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:agrimart/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../data/services/api_service.dart';
import '../../core/utils/responsive.dart';

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
    final l10n = AppLocalizations.of(context)!;
    setState(() { _isAnalyzing = true; _error = null; });
    try {
      final res = await ApiService.instance.diagnoseCrop(_image!.path);
      setState(() { _result = res; _isAnalyzing = false; });
      ref.invalidate(_diagnoseHistoryProvider);
    } catch (e) {
      setState(() { _error = l10n.analysisFailed; _isAnalyzing = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final l10n = AppLocalizations.of(context)!;
    final history = ref.watch(_diagnoseHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.farmerAccent,
          onRefresh: () async => ref.invalidate(_diagnoseHistoryProvider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(r.horizontalPadding, r.rs(12), r.horizontalPadding, r.bottomNavInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.cropDoctor, style: GoogleFonts.spaceGrotesk(fontSize: r.sp(24), fontWeight: FontWeight.w800, color: AppColors.ink)),
                          Text(l10n.cropDoctorSubtitle, style: GoogleFonts.inter(fontSize: r.sp(13), color: AppColors.muted)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: AppColors.farmerTint, borderRadius: BorderRadius.circular(20)),
                      child: Row(children: [
                        const Icon(Icons.auto_awesome, color: AppColors.farmerAccent, size: 14),
                        const SizedBox(width: 4),
                        Text(l10n.aiPowered, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.farmerAccent)),
                      ]),
                    ),
                  ],
                ),
                SizedBox(height: r.rs(16)),
                const OfflineBanner(),
                _StepRow(step: 1, label: l10n.takeCropPhoto, active: _image == null),
                SizedBox(height: r.rs(12)),
                Container(
                  padding: EdgeInsets.all(r.rs(20)),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(r.rs(20)),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppColors.softShadow,
                  ),
                  child: Column(
                    children: [
                      if (_image == null) ...[
                        Container(
                          width: double.infinity,
                          height: r.rs(180),
                          decoration: BoxDecoration(
                            color: AppColors.farmerTint,
                            borderRadius: BorderRadius.circular(r.rs(16)),
                            border: Border.all(color: AppColors.farmerAccent.withValues(alpha: 0.3), width: 2),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🌿', style: TextStyle(fontSize: 52)),
                              SizedBox(height: r.rs(12)),
                              Text(l10n.takeCropPhoto, style: GoogleFonts.spaceGrotesk(fontSize: r.sp(16), fontWeight: FontWeight.w600, color: AppColors.farmerAccent)),
                              Text(l10n.aiIdentifyDisease, style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
                            ],
                          ),
                        ),
                      ] else ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(r.rs(16)),
                          child: Image.file(_image!, height: r.rs(220), width: double.infinity, fit: BoxFit.cover),
                        ),
                      ],
                      SizedBox(height: r.rs(16)),
                      Row(
                        children: [
                          Expanded(child: AppButton(label: l10n.camera, onTap: () => _pickImage(ImageSource.camera), color: AppColors.farmerAccent, icon: Icons.camera_alt_outlined, height: 46)),
                          SizedBox(width: r.rs(12)),
                          Expanded(child: AppButton(label: l10n.gallery, onTap: () => _pickImage(ImageSource.gallery), isOutlined: true, color: AppColors.farmerAccent, icon: Icons.photo_library_outlined, height: 46)),
                        ],
                      ),
                      if (_image != null && !_isAnalyzing && _result == null) ...[
                        SizedBox(height: r.rs(12)),
                        AppButton(label: l10n.analyzeCrop, onTap: _analyze, color: AppColors.farmerAccent, icon: Icons.search_rounded),
                      ],
                    ],
                  ),
                ),
                if (_isAnalyzing) ...[
                  SizedBox(height: r.rs(20)),
                  _StepRow(step: 2, label: l10n.analyzingCrop, active: true),
                  SizedBox(height: r.rs(12)),
                  Container(
                    padding: EdgeInsets.all(r.rs(24)),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(r.rs(16)), boxShadow: AppColors.softShadow),
                    child: Row(
                      children: [
                        SizedBox(width: 40, height: 40, child: CircularProgressIndicator(color: AppColors.farmerAccent, strokeWidth: 3, backgroundColor: AppColors.farmerTint)),
                        SizedBox(width: r.rs(16)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.analyzingCrop, style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink)),
                              Text(l10n.aiWorking, style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_error != null) ...[
                  SizedBox(height: r.rs(16)),
                  Container(
                    padding: EdgeInsets.all(r.rs(16)),
                    decoration: BoxDecoration(color: AppColors.dangerTint, borderRadius: BorderRadius.circular(r.rs(16))),
                    child: Row(children: [
                      const Icon(Icons.error_outline, color: AppColors.danger),
                      SizedBox(width: r.rs(12)),
                      Expanded(child: Text(_error!, style: GoogleFonts.inter(color: AppColors.danger))),
                    ]),
                  ),
                ],
                if (_result != null) ...[
                  SizedBox(height: r.rs(20)),
                  _StepRow(step: 3, label: l10n.analysisResult, active: false, done: true),
                  SizedBox(height: r.rs(12)),
                  Container(
                    padding: EdgeInsets.all(r.rs(20)),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(r.rs(20)),
                      border: Border.all(color: AppColors.farmerAccent.withValues(alpha: 0.3)),
                      boxShadow: AppColors.softShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.analysisResult, style: GoogleFonts.spaceGrotesk(fontSize: r.sp(16), fontWeight: FontWeight.w700, color: AppColors.ink)),
                        SizedBox(height: r.rs(16)),
                        _ResultRow(label: l10n.cropLabel, value: _result!['crop'] ?? 'Unknown'),
                        _ResultRow(label: l10n.detectedIssue, value: _result!['issue'] ?? _result!['disease'] ?? 'None'),
                        _ResultRow(label: l10n.confidence, value: '${_result!['confidence'] ?? 0}%', valueColor: AppColors.success),
                        SizedBox(height: r.rs(12)),
                        const Divider(color: AppColors.border),
                        SizedBox(height: r.rs(12)),
                        Text(l10n.treatmentRecommendation, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted)),
                        SizedBox(height: r.rs(6)),
                        Container(
                          padding: EdgeInsets.all(r.rs(12)),
                          decoration: BoxDecoration(color: AppColors.successTint, borderRadius: BorderRadius.circular(r.rs(12))),
                          child: Text(
                            _result!['treatment'] ?? _result!['recommendation'] ?? '-',
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.success, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: r.rs(28)),
                Text(l10n.scanHistory, style: GoogleFonts.spaceGrotesk(fontSize: r.sp(16), fontWeight: FontWeight.w700, color: AppColors.ink)),
                SizedBox(height: r.rs(12)),
                history.when(
                  loading: () => const ShimmerBox(height: 100, radius: 12),
                  error: (_, __) => Text(l10n.couldNotLoadOrders, style: GoogleFonts.inter(color: AppColors.muted)),
                  data: (list) {
                    if (list.isEmpty) return EmptyState(emoji: '🔬', title: l10n.noScansYet, subtitle: l10n.scanHistorySubtitle);
                    return Container(
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(r.rs(16)), border: Border.all(color: AppColors.border), boxShadow: AppColors.softShadow),
                      child: Column(
                        children: List.generate(list.length, (i) {
                          final h = list[i];
                          return Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.all(r.rs(14)),
                                child: Row(
                                  children: [
                                    Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.farmerTint, borderRadius: BorderRadius.circular(10)), child: Center(child: Text('🌿', style: TextStyle(fontSize: r.sp(18))))),
                                    SizedBox(width: r.rs(12)),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final int step;
  final String label;
  final bool active;
  final bool done;

  const _StepRow({required this.step, required this.label, this.active = false, this.done = false});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final color = done ? AppColors.success : (active ? AppColors.farmerAccent : AppColors.muted);
    return Row(
      children: [
        CircleAvatar(
          radius: r.rs(14),
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text('$step', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, color: color, fontSize: r.sp(12))),
        ),
        SizedBox(width: r.rs(10)),
        Text(label, style: GoogleFonts.inter(fontSize: r.sp(13), fontWeight: FontWeight.w600, color: AppColors.ink)),
      ],
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
