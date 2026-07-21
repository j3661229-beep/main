import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/utils/ai_image_picker.dart';
import 'dart:io';
import 'dart:math';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/services/api_service.dart';
import '../../data/providers/auth_provider.dart';
import '../../core/providers/app_language_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../services/voice_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/widgets/ai_analysis_progress.dart';
import '../../core/utils/responsive.dart';

// ── Crop emoji map ─────────────────────────────────────────────────────────────
const Map<String, String> _cropEmoji = {
  'wheat': '🌾', 'rice': '🍚', 'corn': '🌽', 'maize': '🌽',
  'tomato': '🍅', 'potato': '🥔', 'onion': '🧅', 'sugarcane': '🎋',
  'cotton': '🌸', 'soybean': '🫘', 'mango': '🥭', 'banana': '🍌',
  'chili': '🌶️', 'turmeric': '🟡', 'garlic': '🧄', 'ginger': '🫚',
  'sunflower': '🌻', 'mustard': '🌿', 'groundnut': '🥜', 'lemon': '🍋',
};

String _emojiFor(String crop) {
  final lower = crop.toLowerCase();
  for (final entry in _cropEmoji.entries) {
    if (lower.contains(entry.key)) return entry.value;
  }
  return '🌱';
}

class SoilAnalysisScreen extends ConsumerStatefulWidget {
  const SoilAnalysisScreen({super.key});
  @override
  ConsumerState<SoilAnalysisScreen> createState() => _SoilAnalysisScreenState();
}

class _SoilAnalysisScreenState extends ConsumerState<SoilAnalysisScreen>
    with TickerProviderStateMixin {
  File? _image;
  Map? _result;
  bool _analyzing = false;
  late AnimationController _pulseCtrl;
  late AnimationController _scoreCtrl;
  late Animation<double> _scoreAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _scoreCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600));
    _scoreAnim = CurvedAnimation(parent: _scoreCtrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    ApiService.instance.cancelAiRequest();
    _pulseCtrl.dispose();
    _scoreCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource src) async {
    final picked = await AiImagePicker.pick(src);
    if (picked != null) {
      HapticFeedback.mediumImpact();
      setState(() {
        _image = File(picked.path);
        _result = null;
      });
    }
  }

  Future<void> _analyze() async {
    if (_image == null) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _analyzing = true;
      _result = null;
    });
    _scoreCtrl.reset();
    try {
      final user = ref.read(authProvider).user;
      final language = ref.read(appLanguageProvider).aiName;
      final location =
          "${user?.farmer?['village'] ?? ''}, ${user?.farmer?['district'] ?? ''}";
      final res = await ApiService.instance
          .analyzeSoil(_image!.path, location: location, language: language);
      final analysis = res['analysis'] as Map? ?? {};
      final report = res['report'] as Map? ?? {};
      setState(() {
        _result = {
          ...res,
          'analysis': {
            ...analysis,
            'soilType': analysis['soilType'] ?? report['soilType'],
            'phLevel': analysis['phLevel'] ?? report['phLevel'],
            'nitrogenLevel':
                analysis['nitrogenLevel'] ?? report['nitrogenLevel'],
            'phosphorusLevel':
                analysis['phosphorusLevel'] ?? report['phosphorusLevel'],
            'potassiumLevel':
                analysis['potassiumLevel'] ?? report['potassiumLevel'],
            'treatmentAdvice':
                analysis['treatmentAdvice'] ?? report['treatmentAdvice'],
            'recommendedCrops':
                analysis['recommendedCrops'] ?? report['recommendedCrops'],
            'soilHealth': analysis['soilHealth'] ?? report['soilHealth'],
            'healthScore': analysis['healthScore'] ?? report['healthScore'],
          },
        };
        _analyzing = false;
      });
      await Future.delayed(const Duration(milliseconds: 300));
      _scoreCtrl.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() => _analyzing = false);
      if (isRequestCancelled(e)) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(extractUserFacingError(e)),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _cancelAnalysis() {
    ApiService.instance.cancelAiRequest();
    if (mounted) setState(() => _analyzing = false);
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Rich Header ──────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: r.rs(160),
            pinned: true,
            backgroundColor: const Color(0xFF1A2E12),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _SoilHeader(r: r),
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  r.horizontalPadding, r.rs(20),
                  r.horizontalPadding, r.rs(40)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── How it works pill ──────────────────────────────────
                  FadeInDown(
                    duration: const Duration(milliseconds: 350),
                    child: _HowItWorksBanner(),
                  ),
                  SizedBox(height: r.rs(22)),

                  // ── Image Capture Zone ─────────────────────────────────
                  FadeInUp(
                    duration: const Duration(milliseconds: 400),
                    child: _ImageCaptureZone(
                      image: _image,
                      analyzing: _analyzing,
                      pulseCtrl: _pulseCtrl,
                      onPickImage: _pickImage,
                    ),
                  ),
                  SizedBox(height: r.rs(16)),

                  // ── Action Buttons ─────────────────────────────────────
                  if (_image != null) ...[
                    FadeIn(
                      child: Row(
                        children: [
                          Expanded(
                            child: _OutlineBtn(
                              icon: Icons.refresh_rounded,
                              label: 'Retake',
                              onTap: () => _pickImage(ImageSource.camera),
                            ),
                          ),
                          SizedBox(width: r.rs(12)),
                          Expanded(
                            flex: 2,
                            child: _AnalyzeBtn(
                              analyzing: _analyzing,
                              onTap: _analyze,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: r.rs(28)),
                  ],

                  // ── Analyzing shimmer ─────────────────────────────────
                  if (_analyzing)
                    AiAnalysisProgressCard(
                      title: 'Analyzing soil…',
                      cancelLabel: 'Cancel',
                      onCancel: _cancelAnalysis,
                      steps: const [
                        'Identifying soil composition…',
                        'Measuring NPK levels…',
                        'Finding crop recommendations…',
                        'Generating your report…',
                      ],
                    ),

                  // ── Results ───────────────────────────────────────────
                  if (_result != null) ...[
                    _ResultsSection(
                      result: _result!,
                      scoreAnim: _scoreAnim,
                      onSpeak: _speakResults,
                    ),
                  ],

                  // ── Empty state (no image yet) ─────────────────────────
                  if (_image == null && !_analyzing && _result == null) ...[
                    SizedBox(height: r.rs(8)),
                    _SampleTipsCard(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _speakResults() {
    final advice = _result!['analysis']?['treatmentAdvice'];
    final crops =
        (_result!['analysis']?['recommendedCrops'] as List? ?? []).join(', ');
    VoiceService.instance.speak(
        "$advice. Recommended crops are: $crops",
        languageCode: ref.read(localeProvider).languageCode);
  }
}

// ── Soil Header ────────────────────────────────────────────────────────────────
class _SoilHeader extends StatelessWidget {
  final Responsive r;
  const _SoilHeader({required this.r});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D1F08), Color(0xFF1E3A12), Color(0xFF2D5A1E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Soil texture circles
          Positioned(right: -30, top: -30,
            child: Container(width: 160, height: 160,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: const Color(0xFF8B4513).withValues(alpha: 0.08)))),
          Positioned(left: -20, bottom: -40,
            child: Container(width: 130, height: 130,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03)))),

          Padding(
            padding: EdgeInsets.fromLTRB(
              r.horizontalPadding,
              r.safePadding.top + r.rs(52),
              r.horizontalPadding,
              r.rs(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: r.rs(44), height: r.rs(44),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B4513).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(r.rs(13)),
                        border: Border.all(
                            color: const Color(0xFFA0522D).withValues(alpha: 0.4)),
                      ),
                      child: Center(
                          child: Text('🧪', style: TextStyle(fontSize: r.sp(22)))),
                    ),
                    SizedBox(width: r.rs(14)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Soil Analysis',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: r.sp(24),
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            )),
                        Text('मृदा परीक्षण • AI Powered',
                            style: GoogleFonts.inter(
                              fontSize: r.sp(12),
                              color: Colors.white60,
                            )),
                      ],
                    ),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: r.rs(10), vertical: r.rh(5)),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(r.rs(10)),
                        border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded,
                              color: Color(0xFF90EE90), size: 13),
                          SizedBox(width: r.rs(4)),
                          Text('Gemini AI',
                              style: GoogleFonts.inter(
                                fontSize: r.sp(11),
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF90EE90),
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── How It Works Banner ────────────────────────────────────────────────────────
class _HowItWorksBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final steps = [
      ('📸', 'Photo'),
      ('🤖', 'Analyze'),
      ('📊', 'Results'),
      ('🌱', 'Grow'),
    ];
    return Container(
      padding: EdgeInsets.symmetric(horizontal: r.rs(16), vertical: r.rs(13)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(r.rs(16)),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          ...steps.asMap().entries.expand((e) => [
            Column(
              children: [
                Text(e.value.$1, style: TextStyle(fontSize: r.sp(20))),
                SizedBox(height: r.rs(4)),
                Text(e.value.$2,
                    style: GoogleFonts.inter(
                        fontSize: r.sp(9.5),
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted)),
              ],
            ),
            if (e.key < steps.length - 1) ...[
              SizedBox(width: r.rs(6)),
              Icon(Icons.chevron_right_rounded,
                  color: AppColors.placeholder, size: r.rs(16)),
              SizedBox(width: r.rs(6)),
            ],
          ]),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: r.rs(10), vertical: r.rs(5)),
            decoration: BoxDecoration(
              color: AppColors.farmerTint,
              borderRadius: BorderRadius.circular(r.rs(20)),
            ),
            child: Text('Free Analysis',
                style: GoogleFonts.inter(
                    fontSize: r.sp(10),
                    fontWeight: FontWeight.w700,
                    color: AppColors.farmerAccent)),
          ),
        ],
      ),
    );
  }
}

// ── Image Capture Zone ─────────────────────────────────────────────────────────
class _ImageCaptureZone extends StatelessWidget {
  final File? image;
  final bool analyzing;
  final AnimationController pulseCtrl;
  final void Function(ImageSource) onPickImage;

  const _ImageCaptureZone({
    required this.image,
    required this.analyzing,
    required this.pulseCtrl,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Soil Sample Photo',
            style: GoogleFonts.spaceGrotesk(
                fontSize: r.sp(16),
                fontWeight: FontWeight.w800,
                color: AppColors.ink)),
        SizedBox(height: r.rs(4)),
        Text(
          'Place soil on a white paper in good light for accurate results',
          style: GoogleFonts.inter(fontSize: r.sp(12), color: AppColors.muted),
        ),
        SizedBox(height: r.rs(12)),

        // Main image zone
        GestureDetector(
          onTap: () => _showPickerSheet(context),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: r.rs(220),
            width: double.infinity,
            decoration: BoxDecoration(
              color: image != null
                  ? Colors.transparent
                  : AppColors.farmerTint.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(r.rs(22)),
              border: Border.all(
                color: image != null
                    ? AppColors.farmerAccent
                    : AppColors.farmerAccent.withValues(alpha: 0.3),
                width: image != null ? 2.5 : 1.5,
              ),
              boxShadow: image != null ? AppColors.softShadow : null,
            ),
            child: image != null
                ? _ImagePreview(image: image!, analyzing: analyzing)
                : _EmptyCapture(pulseCtrl: pulseCtrl, r: r),
          ),
        ),

        SizedBox(height: r.rs(10)),

        // Source picker buttons (always shown when no image)
        if (image == null)
          Row(
            children: [
              Expanded(
                child: _SourceBtn(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  color: AppColors.farmerAccent,
                  onTap: () => onPickImage(ImageSource.camera),
                ),
              ),
              SizedBox(width: r.rs(10)),
              Expanded(
                child: _SourceBtn(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  color: const Color(0xFF6B3A10),
                  onTap: () => onPickImage(ImageSource.gallery),
                ),
              ),
            ],
          ),
      ],
    );
  }

  void _showPickerSheet(BuildContext context) {
    final r = context.r;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(r.rs(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: r.rs(40), height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(r.rs(2)),
                ),
              ),
              SizedBox(height: r.rs(16)),
              Text('Add Soil Photo',
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: r.sp(18), fontWeight: FontWeight.w800)),
              SizedBox(height: r.rs(16)),
              _SheetOption(
                emoji: '📷',
                title: 'Take Photo',
                subtitle: 'Use camera for best results',
                onTap: () {
                  Navigator.pop(context);
                  onPickImage(ImageSource.camera);
                },
              ),
              SizedBox(height: r.rs(10)),
              _SheetOption(
                emoji: '🖼️',
                title: 'Choose from Gallery',
                subtitle: 'Select an existing soil photo',
                onTap: () {
                  Navigator.pop(context);
                  onPickImage(ImageSource.gallery);
                },
              ),
              SizedBox(height: r.rs(8)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final File image;
  final bool analyzing;

  const _ImagePreview({required this.image, required this.analyzing});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(r.rs(20)),
          child: Image.file(image, fit: BoxFit.cover),
        ),
        if (analyzing)
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(r.rs(20)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: r.rs(42), height: r.rh(42),
                  child: CircularProgressIndicator(
                    color: Color(0xFF90EE90), strokeWidth: r.rs(3),
                  ),
                ),
                SizedBox(height: r.rs(14)),
                Text('AI is analyzing your soil…',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: r.sp(14),
                      fontWeight: FontWeight.w700,
                    )),
                SizedBox(height: r.rs(4)),
                Text('This takes 5–10 seconds',
                    style: GoogleFonts.inter(
                        color: Colors.white60, fontSize: r.sp(12))),
              ],
            ),
          ),
        if (!analyzing)
          Positioned(
            top: 10, right: 10,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: r.rs(8), vertical: r.rh(4)),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(r.rs(8)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_rounded,
                      color: Colors.white, size: r.sp(12)),
                  SizedBox(width: r.rs(4)),
                  Text('Ready',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: r.sp(10),
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyCapture extends StatelessWidget {
  final AnimationController pulseCtrl;
  final Responsive r;
  const _EmptyCapture({required this.pulseCtrl, required this.r});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return AnimatedBuilder(
      animation: pulseCtrl,
      builder: (_, __) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: r.rs(70), height: r.rs(70),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.farmerAccent.withValues(
                  alpha: 0.08 + pulseCtrl.value * 0.06),
              border: Border.all(
                color: AppColors.farmerAccent.withValues(
                    alpha: 0.25 + pulseCtrl.value * 0.15),
                width: r.rs(2),
              ),
            ),
            child: Center(
              child: Text('🟫', style: TextStyle(fontSize: r.sp(34))),
            ),
          ),
          SizedBox(height: r.rs(14)),
          Text('Tap to add soil photo',
              style: GoogleFonts.spaceGrotesk(
                fontSize: r.sp(15),
                fontWeight: FontWeight.w700,
                color: AppColors.farmerAccent,
              )),
          SizedBox(height: r.rs(4)),
          Text('Camera or gallery',
              style: GoogleFonts.inter(
                  fontSize: r.sp(12), color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _SourceBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SourceBtn({required this.icon, required this.label,
    required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: r.rs(12)),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(r.rs(14)),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: r.rs(18)),
            SizedBox(width: r.rs(7)),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: r.sp(13),
                    fontWeight: FontWeight.w700,
                    color: color)),
          ],
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final String emoji, title, subtitle;
  final VoidCallback onTap;
  const _SheetOption({required this.emoji, required this.title,
    required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(r.rs(14)),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(r.rs(14)),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Text(emoji, style: TextStyle(fontSize: r.sp(28))),
            SizedBox(width: r.rs(14)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: r.sp(14), fontWeight: FontWeight.w700)),
                Text(subtitle,
                    style: GoogleFonts.inter(
                        fontSize: r.sp(12), color: AppColors.muted)),
              ],
            ),
            Spacer(),
            Icon(Icons.arrow_forward_ios_rounded,
                size: r.sp(14), color: AppColors.farmerAccent),
          ],
        ),
      ),
    );
  }
}

// ── Outline + Analyze buttons ──────────────────────────────────────────────────
class _OutlineBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _OutlineBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: r.rs(14)),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(r.rs(14)),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: r.rs(17), color: AppColors.muted),
            SizedBox(width: r.rs(6)),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: r.sp(13),
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

class _AnalyzeBtn extends StatelessWidget {
  final bool analyzing;
  final VoidCallback onTap;
  const _AnalyzeBtn({required this.analyzing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return GestureDetector(
      onTap: analyzing ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: r.rs(14)),
        decoration: BoxDecoration(
          gradient: analyzing
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF1B3A12), Color(0xFF3D7A30)]),
          color: analyzing ? AppColors.border : null,
          borderRadius: BorderRadius.circular(r.rs(14)),
          boxShadow: analyzing
              ? null
              : [BoxShadow(
                  color: AppColors.farmerAccent.withValues(alpha: 0.4),
                  blurRadius: r.rs(14), offset: Offset(0, 5))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (analyzing)
              SizedBox(
                width: r.rs(16), height: r.rs(16),
                child: CircularProgressIndicator(
                    strokeWidth: r.rs(2), color: AppColors.farmerAccent),
              )
            else
              Icon(Icons.science_rounded, color: Colors.white, size: r.sp(18)),
            SizedBox(width: r.rs(8)),
            Text(
              analyzing ? 'Analyzing…' : 'Analyze Soil',
              style: GoogleFonts.spaceGrotesk(
                fontSize: r.sp(14),
                fontWeight: FontWeight.w700,
                color: analyzing ? AppColors.muted : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Results Section ────────────────────────────────────────────────────────────
class _ResultsSection extends StatelessWidget {
  final Map result;
  final Animation<double> scoreAnim;
  final VoidCallback onSpeak;

  const _ResultsSection({
    required this.result,
    required this.scoreAnim,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final analysis = result['analysis'] as Map? ?? {};
    final soilType = analysis['soilType']?.toString() ?? 'Unknown';
    final ph = analysis['phLevel']?.toString() ?? 'N/A';
    final nitrogen = analysis['nitrogenLevel']?.toString() ?? 'N/A';
    final phosphorus = analysis['phosphorusLevel']?.toString() ?? 'N/A';
    final potassium = analysis['potassiumLevel']?.toString() ?? 'N/A';
    final advice = analysis['treatmentAdvice']?.toString() ?? '';
    final crops = (analysis['recommendedCrops'] as List? ?? [])
        .map((c) => c.toString())
        .toList();
    final rawScore = analysis['healthScore'];
    final healthScore = rawScore is num
        ? (rawScore.toDouble()).clamp(0.0, 100.0)
        : _inferScore(nitrogen, phosphorus, potassium);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────────────
        FadeInDown(
          duration: const Duration(milliseconds: 400),
          child: Row(
            children: [
              Container(
                width: r.rs(36), height: r.rs(36),
                decoration: BoxDecoration(
                  color: AppColors.successTint,
                  borderRadius: BorderRadius.circular(r.rs(10)),
                ),
                child: Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: r.sp(20)),
              ),
              SizedBox(width: r.rs(10)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Analysis Complete',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: r.sp(17),
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink)),
                  Text('Your soil report is ready',
                      style: GoogleFonts.inter(
                          fontSize: r.sp(12), color: AppColors.muted)),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: onSpeak,
                child: Container(
                  padding: EdgeInsets.all(r.rs(9)),
                  decoration: BoxDecoration(
                    color: AppColors.farmerTint,
                    borderRadius: BorderRadius.circular(r.rs(11)),
                    border: Border.all(
                        color: AppColors.farmerAccent.withValues(alpha: 0.3)),
                  ),
                  child: Icon(Icons.volume_up_rounded,
                      color: AppColors.farmerAccent, size: r.rs(18)),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: r.rs(18)),

        // ── Health Score Ring + Soil Type ────────────────────────────────
        FadeInUp(
          delay: const Duration(milliseconds: 60),
          duration: const Duration(milliseconds: 500),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HealthScoreRing(score: healthScore, anim: scoreAnim),
              SizedBox(width: r.rs(14)),
              Expanded(
                child: Column(
                  children: [
                    _InfoTile(
                      emoji: '🟫',
                      label: 'Soil Type',
                      value: soilType,
                      color: const Color(0xFF8B4513),
                    ),
                    SizedBox(height: r.rs(10)),
                    _InfoTile(
                      emoji: '⚗️',
                      label: 'pH Level',
                      value: ph,
                      color: _phColor(ph),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: r.rs(18)),

        // ── NPK Gauge Card ───────────────────────────────────────────────
        FadeInUp(
          delay: const Duration(milliseconds: 100),
          duration: const Duration(milliseconds: 500),
          child: Container(
            padding: EdgeInsets.all(r.rs(18)),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(r.rs(20)),
              border: Border.all(color: AppColors.border),
              boxShadow: AppColors.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('📊 NPK Levels',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: r.sp(15),
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink)),
                    const Spacer(),
                    Text('Nitrogen · Phosphorus · Potassium',
                        style: GoogleFonts.inter(
                            fontSize: r.sp(9.5), color: AppColors.placeholder)),
                  ],
                ),
                SizedBox(height: r.rs(16)),
                _NPKGauge(
                    label: 'Nitrogen (N)', value: nitrogen,
                    emoji: '🌿', color: const Color(0xFF2E7D52),
                    anim: scoreAnim),
                SizedBox(height: r.rs(12)),
                _NPKGauge(
                    label: 'Phosphorus (P)', value: phosphorus,
                    emoji: '💧', color: const Color(0xFF1565C0),
                    anim: scoreAnim),
                SizedBox(height: r.rs(12)),
                _NPKGauge(
                    label: 'Potassium (K)', value: potassium,
                    emoji: '⚡', color: const Color(0xFFF57F17),
                    anim: scoreAnim),
              ],
            ),
          ),
        ),
        SizedBox(height: r.rs(16)),

        // ── AI Advisory card ─────────────────────────────────────────────
        if (advice.isNotEmpty)
          FadeInUp(
            delay: const Duration(milliseconds: 140),
            duration: const Duration(milliseconds: 500),
            child: Container(
              padding: EdgeInsets.all(r.rs(18)),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D1F08), Color(0xFF1A3A10), Color(0xFF2A5518)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(r.rs(20)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.farmerAccent.withValues(alpha: 0.35),
                    blurRadius: r.rs(18),
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(r.rs(8)),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(r.rs(10)),
                        ),
                        child: Text('✨',
                            style: TextStyle(fontSize: r.sp(16))),
                      ),
                      SizedBox(width: r.rs(12)),
                      Text('AI Advisory',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontSize: r.sp(16),
                            fontWeight: FontWeight.w800,
                          )),
                      Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: r.rs(8), vertical: r.rh(3)),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(r.rs(8)),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Text('Gemini',
                            style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: r.sp(10),
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  SizedBox(height: r.rs(14)),
                  Text(advice,
                      style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: r.sp(13.5),
                          height: r.rh(1.6),
                          fontWeight: FontWeight.w400)),
                ],
              ),
            ),
          ),
        SizedBox(height: r.rs(16)),

        // ── Recommended Crops ────────────────────────────────────────────
        if (crops.isNotEmpty)
          FadeInUp(
            delay: const Duration(milliseconds: 180),
            duration: const Duration(milliseconds: 500),
            child: Container(
              padding: EdgeInsets.all(r.rs(18)),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(r.rs(20)),
                border: Border.all(color: AppColors.border),
                boxShadow: AppColors.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('🌱',
                          style: TextStyle(fontSize: r.sp(20))),
                      SizedBox(width: r.rs(8)),
                      Text('Best Crops for Your Soil',
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: r.sp(15),
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink)),
                    ],
                  ),
                  SizedBox(height: r.rs(4)),
                  Text('Based on soil type, NPK & pH',
                      style: GoogleFonts.inter(
                          fontSize: r.sp(11), color: AppColors.muted)),
                  SizedBox(height: r.rs(14)),
                  Wrap(
                    spacing: r.rs(8),
                    runSpacing: r.rs(8),
                    children: crops.map((crop) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: r.rs(12), vertical: r.rs(8)),
                        decoration: BoxDecoration(
                          color: AppColors.farmerTint,
                          borderRadius: BorderRadius.circular(r.rs(22)),
                          border: Border.all(
                              color: AppColors.farmerAccent.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_emojiFor(crop),
                                style: TextStyle(fontSize: r.sp(14))),
                            SizedBox(width: r.rs(5)),
                            Text(crop,
                                style: GoogleFonts.inter(
                                  fontSize: r.sp(12.5),
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.farmerAccent,
                                )),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        SizedBox(height: r.rs(16)),

        // ── Disclaimer ───────────────────────────────────────────────────
        FadeIn(
          delay: const Duration(milliseconds: 200),
          child: Container(
            padding: EdgeInsets.all(r.rs(12)),
            decoration: BoxDecoration(
              color: AppColors.warningTint,
              borderRadius: BorderRadius.circular(r.rs(12)),
              border:
                  Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('⚠️', style: TextStyle(fontSize: r.sp(14))),
                SizedBox(width: r.rs(8)),
                Expanded(
                  child: Text(
                    'AI analysis is indicative. For critical decisions, '
                    'verify with a certified soil testing lab.',
                    style: GoogleFonts.inter(
                        fontSize: r.sp(11),
                        color: AppColors.warning,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  double _inferScore(String n, String p, String k) {
    double s = 50;
    final vals = [n, p, k].map((v) => v.toLowerCase()).toList();
    for (final v in vals) {
      if (v.contains('high') || v.contains('optimal') || v.contains('good')) s += 10;
      if (v.contains('low') || v.contains('deficient')) s -= 10;
    }
    return s.clamp(10, 95);
  }

  Color _phColor(String ph) {
    final n = double.tryParse(ph.replaceAll(RegExp(r'[^0-9.]'), ''));
    if (n == null) return AppColors.farmerAccent;
    if (n < 5.5) return AppColors.danger;
    if (n > 7.5) return AppColors.warning;
    return AppColors.success;
  }
}

// ── Health Score Ring ──────────────────────────────────────────────────────────
class _HealthScoreRing extends StatelessWidget {
  final double score;
  final Animation<double> anim;
  const _HealthScoreRing({required this.score, required this.anim});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final size = r.rs(100);
    final color = score >= 70
        ? AppColors.success
        : score >= 40
            ? AppColors.warning
            : AppColors.danger;

    final label = score >= 70 ? 'Good' : score >= 40 ? 'Fair' : 'Poor';

    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => SizedBox(
        width: size, height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(size, size),
              painter: _RingPainter(
                  progress: (anim.value * score / 100).clamp(0, 1),
                  color: color),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${(anim.value * score).toInt()}',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: r.sp(22),
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    )),
                Text(label,
                    style: GoogleFonts.inter(
                      fontSize: r.sp(10),
                      fontWeight: FontWeight.w700,
                      color: color,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width / 2 - 8;
    const strokeW = 8.0;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    // Background ring
    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi,
      false,
      Paint()
        ..color = AppColors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round,
    );

    // Progress arc
    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

// ── Info Tile ─────────────────────────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final String emoji, label, value;
  final Color color;
  const _InfoTile({required this.emoji, required this.label,
    required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Container(
      padding: EdgeInsets.all(r.rs(12)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(r.rs(14)),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: r.sp(20))),
          SizedBox(width: r.rs(8)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: r.sp(10),
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600)),
                Text(value,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: r.sp(13.5),
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── NPK Gauge ─────────────────────────────────────────────────────────────────
class _NPKGauge extends StatelessWidget {
  final String label, value, emoji;
  final Color color;
  final Animation<double> anim;
  const _NPKGauge({required this.label, required this.value,
    required this.emoji, required this.color, required this.anim});

  double _progress() {
    final v = value.toLowerCase();
    if (v.contains('high') || v.contains('optimal') || v.contains('very good')) return 0.88;
    if (v.contains('good') || v.contains('adequate')) return 0.72;
    if (v.contains('medium') || v.contains('moderate')) return 0.55;
    if (v.contains('low') || v.contains('deficient')) return 0.22;
    if (v.contains('very low')) return 0.08;
    return 0.5;
  }

  String _statusLabel() {
    final v = value.toLowerCase();
    if (v.contains('high') || v.contains('optimal')) return 'OPTIMAL';
    if (v.contains('good')) return 'GOOD';
    if (v.contains('medium') || v.contains('moderate')) return 'MEDIUM';
    if (v.contains('low')) return 'LOW';
    return value.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final progress = _progress();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: TextStyle(fontSize: r.sp(15))),
            SizedBox(width: r.rs(7)),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: r.sp(12.5),
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink)),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: r.rs(9), vertical: r.rs(3)),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(r.rs(10)),
              ),
              child: Text(_statusLabel(),
                  style: GoogleFonts.inter(
                      fontSize: r.sp(9.5),
                      fontWeight: FontWeight.w900,
                      color: color,
                      letterSpacing: 0.5)),
            ),
          ],
        ),
        SizedBox(height: r.rs(8)),
        AnimatedBuilder(
          animation: anim,
          builder: (_, __) => Stack(
            children: [
              Container(
                height: r.rs(7),
                decoration: BoxDecoration(
                  color: AppColors.border.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(r.rs(4)),
                ),
              ),
              LayoutBuilder(
                builder: (_, constraints) => AnimatedContainer(
                  duration: const Duration(milliseconds: 1400),
                  curve: Curves.easeOutCubic,
                  height: r.rs(7),
                  width: constraints.maxWidth * anim.value * progress,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [color.withValues(alpha: 0.6), color]),
                    borderRadius: BorderRadius.circular(r.rs(4)),
                    boxShadow: [
                      BoxShadow(
                          color: color.withValues(alpha: 0.35),
                          blurRadius: r.rs(6),
                          offset: const Offset(0, 2)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Sample Tips Card (shown when no image) ────────────────────────────────────
class _SampleTipsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final tips = [
      ('☀️', 'Good lighting', 'Take photo in natural light'),
      ('📋', 'White background', 'Place soil on white paper'),
      ('🔍', 'Close-up shot', 'Fill the frame with soil'),
      ('💧', 'Moist sample', 'Slightly moist gives better results'),
    ];
    return Container(
      padding: EdgeInsets.all(r.rs(18)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(r.rs(20)),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📸 Tips for Best Results',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: r.sp(15), fontWeight: FontWeight.w800, color: AppColors.ink)),
          SizedBox(height: r.rs(14)),
          ...tips.map((t) => Padding(
            padding: EdgeInsets.only(bottom: r.rs(10)),
            child: Row(
              children: [
                Text(t.$1, style: TextStyle(fontSize: r.sp(18))),
                SizedBox(width: r.rs(12)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.$2,
                        style: GoogleFonts.inter(
                            fontSize: r.sp(12.5),
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink)),
                    Text(t.$3,
                        style: GoogleFonts.inter(
                            fontSize: r.sp(11), color: AppColors.muted)),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
