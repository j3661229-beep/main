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
    if (_success) return _SuccessView(onDone: () => context.go('/dealer'));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Advance Payment', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w700)),
        leading: GestureDetector(onTap: () => context.pop(), child: const Icon(Icons.arrow_back_rounded)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Advance summary ──────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.dealerGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: AppColors.dealerAccent.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Advance Amount (20%)', style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
                      const SizedBox(height: 4),
                      Text(formatRupee(_advance), style: GoogleFonts.spaceGrotesk(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('Total Deal: ${formatRupee(_total)}', style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
                    ],
                  ),
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
                    child: const Center(child: Text('💰', style: TextStyle(fontSize: 30))),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── UPI Payment section ──────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: AppColors.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pay via UPI', style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  const SizedBox(height: 16),

                  // Farmer UPI
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.dealerTint, borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: const Center(child: Text('📱', style: TextStyle(fontSize: 22)))),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_farmerName, style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.dealerAccent)),
                              Text(_farmerUpi, style: GoogleFonts.inter(fontSize: 13, color: AppColors.dealerAccent.withValues(alpha: 0.8))),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: _farmerUpi));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('UPI ID copied!'), behavior: SnackBarBehavior.floating));
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: AppColors.dealerAccent, borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.copy_rounded, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // QR code placeholder
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        // Simulated QR
                        Container(
                          width: 160, height: 160,
                          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('▪▪▪▪▪▪▪', style: TextStyle(fontSize: 18, letterSpacing: 4)),
                              const Text('▪     ▪', style: TextStyle(fontSize: 18, letterSpacing: 6)),
                              const Text('▪ ▪▪▪ ▪', style: TextStyle(fontSize: 18, letterSpacing: 4)),
                              const Text('▪     ▪', style: TextStyle(fontSize: 18, letterSpacing: 6)),
                              const Text('▪▪▪▪▪▪▪', style: TextStyle(fontSize: 18, letterSpacing: 4)),
                              const SizedBox(height: 8),
                              Text('QR Code', style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text('Scan to pay ${formatRupee(_advance)}', style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Upload screenshot
                  Text('Upload Payment Screenshot *', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.muted)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickScreenshot,
                    child: Container(
                      height: _screenshot != null ? 160 : 80,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _screenshot != null ? AppColors.dealerAccent : AppColors.border, style: BorderStyle.solid),
                      ),
                      child: _screenshot != null
                          ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.file(_screenshot!, fit: BoxFit.cover))
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.upload_file_outlined, color: AppColors.muted, size: 28),
                                const SizedBox(height: 6),
                                Text('Tap to upload screenshot', style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted)),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.dangerTint, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: AppColors.danger, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: GoogleFonts.inter(fontSize: 13, color: AppColors.danger))),
                ]),
              ),
            ],

            const SizedBox(height: 24),
            AppButton(
              label: 'Confirm Deal & Submit',
              onTap: _submitDeal,
              isLoading: _isSubmitting,
              color: AppColors.dealerAccent,
              icon: Icons.check_circle_outline_rounded,
            ),
            const SizedBox(height: 12),
            Text(
              '⚠️ Payment confirmation is required. Upload screenshot after paying via UPI.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 80),
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
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(color: AppColors.successTint, shape: BoxShape.circle),
              child: const Center(child: Text('✅', style: TextStyle(fontSize: 52))),
            ),
            const SizedBox(height: 24),
            Text('Deal Sent!', style: GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.success)),
            const SizedBox(height: 8),
            Text('Your offer has been sent to the farmer.\nAdvance payment recorded.', style: GoogleFonts.inter(fontSize: 14, color: AppColors.muted, height: 1.6), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            AppButton(label: 'Back to Dashboard', onTap: onDone, color: AppColors.dealerAccent, icon: Icons.home_rounded),
          ],
        ),
      ),
    ),
  );
}

