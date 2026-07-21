import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../utils/responsive.dart';

/// Shared in-flight AI progress card with elapsed time and cancel.
class AiAnalysisProgressCard extends StatefulWidget {
  final String title;
  final String? subtitle;
  final List<String>? steps;
  final VoidCallback onCancel;
  final String cancelLabel;
  final Color accentColor;

  const AiAnalysisProgressCard({
    super.key,
    required this.title,
    required this.onCancel,
    this.subtitle,
    this.steps,
    this.cancelLabel = 'Cancel',
    this.accentColor = AppColors.farmerAccent,
  });

  @override
  State<AiAnalysisProgressCard> createState() => _AiAnalysisProgressCardState();
}

class _AiAnalysisProgressCardState extends State<AiAnalysisProgressCard> {
  Timer? _timer;
  int _elapsed = 0;
  int _stepIndex = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsed++;
        final steps = widget.steps;
        if (steps != null && steps.isNotEmpty && _elapsed % 3 == 0) {
          _stepIndex = (_stepIndex + 1) % steps.length;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _statusText {
    final steps = widget.steps;
    if (steps != null && steps.isNotEmpty) return steps[_stepIndex];
    return widget.subtitle ?? 'This may take a moment on slow networks…';
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Container(
      padding: EdgeInsets.all(r.rs(18)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(r.rs(16)),
        border: Border.all(color: widget.accentColor.withValues(alpha: 0.25)),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: r.rs(36),
                height: r.rs(36),
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: widget.accentColor,
                  backgroundColor: widget.accentColor.withValues(alpha: 0.12),
                ),
              ),
              SizedBox(width: r.rs(14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: r.sp(15),
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    SizedBox(height: r.rs(2)),
                    Text(
                      _elapsed > 0 ? '$_statusText · ${_elapsed}s' : _statusText,
                      style: GoogleFonts.inter(
                        fontSize: r.sp(12),
                        color: AppColors.muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: r.rs(14)),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: widget.onCancel,
              icon: Icon(Icons.close_rounded, size: r.rs(16), color: AppColors.muted),
              label: Text(
                widget.cancelLabel,
                style: GoogleFonts.inter(
                  fontSize: r.sp(13),
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: r.rs(10), vertical: r.rs(6)),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact chat-style analyzing row with cancel (Kisan AI).
class AiAnalyzingBubble extends StatelessWidget {
  final VoidCallback onCancel;
  final String label;
  final String cancelLabel;

  const AiAnalyzingBubble({
    super.key,
    required this.onCancel,
    this.label = 'Analyzing…',
    this.cancelLabel = 'Cancel',
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Padding(
      padding: EdgeInsets.only(bottom: r.rs(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: r.rs(34),
            height: r.rs(34),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(r.rs(10)),
            ),
            child: const Center(child: Text('🌾', style: TextStyle(fontSize: 16))),
          ),
          SizedBox(width: r.rs(8)),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: r.rs(16), vertical: r.rs(12)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(r.rs(20)),
                border: Border.all(color: AppColors.border),
                boxShadow: AppColors.softShadow,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: r.rs(14),
                    height: r.rs(14),
                    child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.farmerAccent),
                  ),
                  SizedBox(width: r.rs(10)),
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.inter(fontSize: r.sp(13), color: AppColors.muted),
                    ),
                  ),
                  TextButton(
                    onPressed: onCancel,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: r.rs(8), vertical: r.rs(4)),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      cancelLabel,
                      style: GoogleFonts.inter(
                        fontSize: r.sp(12),
                        fontWeight: FontWeight.w600,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
