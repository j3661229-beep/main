import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/services/api_service.dart';
import '../../core/utils/responsive.dart';

class AdvancePaymentScreen extends ConsumerStatefulWidget {
  final Map dealContext;
  const AdvancePaymentScreen({super.key, required this.dealContext});
  @override
  ConsumerState<AdvancePaymentScreen> createState() => _AdvancePaymentScreenState();
}

class _AdvancePaymentScreenState extends ConsumerState<AdvancePaymentScreen> {
  File? _screenshot;
  bool _isSubmitting = false;
  bool _success = false;
  String? _error;
  String _payMode = 'UPI';

  double get _total    => (widget.dealContext['total'] as num?)?.toDouble() ?? 0;
  double get _advance  => _total * 0.20;

  // Farmer's UPI (from listing)
  String get _farmerUpi => widget.dealContext['listing']?['farmerUpi'] ?? 'farmer@upi';
  String get _farmerName => widget.dealContext['listing']?['farmerName'] ?? widget.dealContext['listing']?['farmer']?['name'] ?? 'Farmer';

  Future<void> _pickScreenshot() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _screenshot = File(picked.path));
  }

  Future<void> _submitDeal() async {
    setState(() { _isSubmitting = true; _error = null; });
    try {
      final listing  = widget.dealContext['listing'] as Map;
      await ApiService.instance.createDeal({
        'listingId':  listing['id'],
        'offerPrice': widget.dealContext['offerPrice'],
        'pickupDate': widget.dealContext['pickupDate'],
        'advancePaid': true,
        'advanceAmount': _advance,
        'paymentMode': _payMode,
      });
      HapticFeedback.mediumImpact();
      setState(() { _success = true; _isSubmitting = false; });
    } catch (e) {
      setState(() { _isSubmitting = false; _error = e.toString().replaceAll('Exception: ', ''); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    if (_success) return _SuccessView(onDone: () => context.go('/dealer'));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Advance Payment', style: GoogleFonts.spaceGrotesk(fontSize: r.sp(18), fontWeight: FontWeight.w700)),
        leading: GestureDetector(onTap: () => context.pop(), child: const Icon(Icons.arrow_back_rounded)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(r.rs(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Advance summary ──────────────────────────
            Container(
              padding: EdgeInsets.all(r.rs(20)),
              decoration: BoxDecoration(
                gradient: AppColors.dealerGradient,
                borderRadius: BorderRadius.circular(r.rs(20)),
                boxShadow: [BoxShadow(color: AppColors.dealerAccent.withValues(alpha: 0.3), blurRadius: r.rs(16), offset: Offset(0, 8))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Advance Amount (20%)', style: GoogleFonts.inter(fontSize: r.sp(12), color: Colors.white.withValues(alpha: 0.8))),
                      SizedBox(height: r.rh(4)),
                      Text(formatRupee(_advance), style: GoogleFonts.spaceGrotesk(fontSize: r.sp(32), fontWeight: FontWeight.w800, color: Colors.white)),
                      SizedBox(height: r.rh(4)),
                      Text('Total Deal: ${formatRupee(_total)}', style: GoogleFonts.inter(fontSize: r.sp(12), color: Colors.white.withValues(alpha: 0.7))),
                    ],
                  ),
                  Container(
                    width: r.rs(60), height: 60,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(r.rs(16))),
                    child: Center(child: Text('💰', style: TextStyle(fontSize: r.sp(30)))),
                  ),
                ],
              ),
            ),

            SizedBox(height: r.rh(20)),

            // ── UPI Payment section ──────────────────────
            Container(
              padding: EdgeInsets.all(r.rs(20)),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(r.rs(20)),
                border: Border.all(color: AppColors.border),
                boxShadow: AppColors.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pay via UPI', style: GoogleFonts.spaceGrotesk(fontSize: r.sp(15), fontWeight: FontWeight.w700, color: AppColors.ink)),
                  SizedBox(height: r.rh(16)),

                  // Farmer UPI
                  Container(
                    padding: EdgeInsets.all(r.rs(16)),
                    decoration: BoxDecoration(color: AppColors.dealerTint, borderRadius: BorderRadius.circular(r.rs(14))),
                    child: Row(
                      children: [
                        Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(r.rs(12))), child: Center(child: Text('📱', style: TextStyle(fontSize: r.sp(22))))),
                        SizedBox(width: r.rs(12)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_farmerName, style: GoogleFonts.spaceGrotesk(fontSize: r.sp(14), fontWeight: FontWeight.w700, color: AppColors.dealerAccent)),
                              Text(_farmerUpi, style: GoogleFonts.inter(fontSize: r.sp(13), color: AppColors.dealerAccent.withValues(alpha: 0.8))),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: _farmerUpi));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('UPI ID copied!'), behavior: SnackBarBehavior.floating));
                          },
                          child: Container(
                            padding: EdgeInsets.all(r.rs(8)),
                            decoration: BoxDecoration(color: AppColors.dealerAccent, borderRadius: BorderRadius.circular(r.rs(10))),
                            child: Icon(Icons.copy_rounded, color: Colors.white, size: r.sp(16)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: r.rh(16)),

                  // QR code placeholder
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(r.rs(20)),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(r.rs(14)),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        // Simulated QR
                        Container(
                          width: r.rs(160), height: 160,
                          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(r.rs(12))),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('▪▪▪▪▪▪▪', style: TextStyle(fontSize: r.sp(18), letterSpacing: 4)),
                              Text('▪     ▪', style: TextStyle(fontSize: r.sp(18), letterSpacing: 6)),
                              Text('▪ ▪▪▪ ▪', style: TextStyle(fontSize: r.sp(18), letterSpacing: 4)),
                              Text('▪     ▪', style: TextStyle(fontSize: r.sp(18), letterSpacing: 6)),
                              Text('▪▪▪▪▪▪▪', style: TextStyle(fontSize: r.sp(18), letterSpacing: 4)),
                              SizedBox(height: r.rh(8)),
                              Text('QR Code', style: GoogleFonts.inter(fontSize: r.sp(11), color: AppColors.muted)),
                            ],
                          ),
                        ),
                        SizedBox(height: r.rh(12)),
                        Text('Scan to pay ${formatRupee(_advance)}', style: GoogleFonts.inter(fontSize: r.sp(13), color: AppColors.muted)),
                      ],
                    ),
                  ),

                  SizedBox(height: r.rh(20)),

                  // Upload screenshot
                  Text('Upload Payment Screenshot *', style: GoogleFonts.inter(fontSize: r.sp(13), fontWeight: FontWeight.w500, color: AppColors.muted)),
                  SizedBox(height: r.rh(8)),
                  GestureDetector(
                    onTap: _pickScreenshot,
                    child: Container(
                      height: _screenshot != null ? 160 : 80,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(r.rs(14)),
                        border: Border.all(color: _screenshot != null ? AppColors.dealerAccent : AppColors.border, style: BorderStyle.solid),
                      ),
                      child: _screenshot != null
                          ? ClipRRect(borderRadius: BorderRadius.circular(r.rs(14)), child: Image.file(_screenshot!, fit: BoxFit.cover))
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.upload_file_outlined, color: AppColors.muted, size: r.sp(28)),
                                SizedBox(height: r.rh(6)),
                                Text('Tap to upload screenshot', style: GoogleFonts.inter(fontSize: r.sp(13), color: AppColors.muted)),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),

            if (_error != null) ...[
              SizedBox(height: r.rh(16)),
              Container(
                padding: EdgeInsets.all(r.rs(12)),
                decoration: BoxDecoration(color: AppColors.dangerTint, borderRadius: BorderRadius.circular(r.rs(12))),
                child: Row(children: [
                  Icon(Icons.error_outline, color: AppColors.danger, size: r.sp(16)),
                  SizedBox(width: r.rs(8)),
                  Expanded(child: Text(_error!, style: GoogleFonts.inter(fontSize: r.sp(13), color: AppColors.danger))),
                ]),
              ),
            ],

            SizedBox(height: r.rh(24)),
            AppButton(
              label: 'Confirm Deal & Submit',
              onTap: _submitDeal,
              isLoading: _isSubmitting,
              color: AppColors.dealerAccent,
              icon: Icons.check_circle_outline_rounded,
            ),
            SizedBox(height: r.rh(12)),
            Text(
              '⚠️ Payment confirmation is required. Upload screenshot after paying via UPI.',
              style: GoogleFonts.inter(fontSize: r.sp(12), color: AppColors.muted, height: 1.5),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: r.rh(80)),
          ],
        ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final VoidCallback onDone;
  const _SuccessView({required this.onDone});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Scaffold(
    backgroundColor: AppColors.background,
    body: Center(
      child: Padding(
        padding: EdgeInsets.all(r.rs(40)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: r.rs(100), height: 100,
              decoration: BoxDecoration(color: AppColors.successTint, shape: BoxShape.circle),
              child: Center(child: Text('✅', style: TextStyle(fontSize: r.sp(52)))),
            ),
            SizedBox(height: r.rh(24)),
            Text('Deal Sent!', style: GoogleFonts.spaceGrotesk(fontSize: r.sp(28), fontWeight: FontWeight.w800, color: AppColors.success)),
            SizedBox(height: r.rh(8)),
            Text('Your offer has been sent to the farmer.\nAdvance payment recorded.', style: GoogleFonts.inter(fontSize: r.sp(14), color: AppColors.muted, height: 1.6), textAlign: TextAlign.center),
            SizedBox(height: r.rh(32)),
            AppButton(label: 'Back to Dashboard', onTap: onDone, color: AppColors.dealerAccent, icon: Icons.home_rounded),
          ],
        ),
      ),
    ),
    );
  }
}

