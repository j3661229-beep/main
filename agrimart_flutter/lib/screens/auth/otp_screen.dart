import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class OTPScreen extends ConsumerStatefulWidget {
  final String phone;
  final String role;
  const OTPScreen({super.key, required this.phone, required this.role});

  @override
  ConsumerState<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends ConsumerState<OTPScreen> {
  final _otpCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _showNameField = false;
  int _resendTimer = 30;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Pre-fill OTP for dev convenience
    _otpCtrl.text = '123456';
    _showNameField = true;
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() { if (_resendTimer > 0) _resendTimer--; });
      return _resendTimer > 0;
    });
  }

  Future<void> _verifyOTP() async {
    if (_otpCtrl.text.length != 6) return;
    try {
      final user = await ref.read(authProvider.notifier).verifyOTP(
        phone: widget.phone,
        otp: _otpCtrl.text,
        name: _nameCtrl.text.isNotEmpty ? _nameCtrl.text : null,
        language: 'marathi',
        role: widget.role,
      );
      if (mounted) context.go(user.isFarmer ? '/farmer' : '/supplier');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid OTP. Try again.'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                GestureDetector(onTap: () => context.pop(), child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white)),
                const SizedBox(width: 12),
                const Text('OTP Verify करा', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
              ]),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                ),
                padding: const EdgeInsets.all(28),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SizedBox(height: 16),
                  const Text('💬', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  Text('OTP Enter करा', style: AppTextStyles.headingXL.copyWith(color: AppColors.primary)),
                  const SizedBox(height: 4),
                  Text('Sent to WhatsApp: ${widget.phone}', style: AppTextStyles.bodySM),
                  const SizedBox(height: 28),
                  // 6-digit OTP field
                  TextFormField(
                    controller: _otpCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: AppTextStyles.displayLarge.copyWith(letterSpacing: 12, color: AppColors.primary),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '· · · · · ·',
                      hintStyle: AppTextStyles.displayLarge.copyWith(letterSpacing: 8, color: AppColors.textTertiary),
                    ),
                    onChanged: (v) {
                      if (v.length == 6) setState(() => _showNameField = true);
                      if (v.length == 6) FocusScope.of(context).nextFocus();
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_showNameField) ...[
                    const SizedBox(height: 12),
                    Text('तुमचे नाव (Your Name)', style: AppTextStyles.labelLG.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(hintText: 'Enter your full name'),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Resend
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    if (_resendTimer > 0)
                      Text('Resend in ${_resendTimer}s', style: AppTextStyles.bodySM)
                    else
                      TextButton(
                        onPressed: () {
                          ref.read(authProvider.notifier).sendOTP(widget.phone, widget.role);
                          setState(() => _resendTimer = 30);
                          _startTimer();
                        },
                        child: const Text('Resend OTP'),
                      ),
                  ]),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: auth.isLoading ? null : _verifyOTP,
                    child: auth.isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Verify & Login ✅'),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
