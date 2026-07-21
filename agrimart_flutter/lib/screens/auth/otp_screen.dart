import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/indian_languages.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../data/providers/auth_provider.dart';
import '../../core/utils/responsive.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;
  final String role;
  final String language;
  const OtpScreen({super.key, required this.phone, required this.role, required this.language});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpCtrl = TextEditingController();
  final _focusNode = FocusNode();
  bool _isLoading = false;
  String? _error;
  int _resendSeconds = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      if (IndianLanguages.isSupported(widget.language)) {
        ref.read(localeProvider.notifier).setLocale(Locale(widget.language));
      }
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_resendSeconds > 0) {
        setState(() => _resendSeconds--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _otpCtrl.dispose();
    _focusNode.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _verify() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length < 6) {
      setState(() => _error = 'Enter the 6-digit OTP');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      await ref.read(authProvider.notifier).verifyOTP(
        phone: widget.phone,
        otp: otp,
        role: widget.role,
        language: widget.language,
      );
      if (!mounted) return;
      final setupComplete = ref.read(authProvider).farmSetupComplete;
      setState(() => _isLoading = false);
      context.go(setupComplete ? '/farmer' : '/farmer/setup');
    } catch (e) {
      _otpCtrl.clear();
      _focusNode.requestFocus();
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _resend() async {
    try {
      await ref.read(authProvider.notifier).sendOTP(phone: widget.phone, role: widget.role);
      setState(() => _resendSeconds = 30);
      _startTimer();
    } catch (e) {
      setState(() => _error = 'Failed to resend OTP');
    }
  }

  void _onOtpChanged(String value) {
    final cleaned = value.replaceAll(RegExp(r'\D'), '');
    final digits = cleaned.length > 6 ? cleaned.substring(0, 6) : cleaned;
    if (digits != _otpCtrl.text) {
      _otpCtrl.value = TextEditingValue(
        text: digits,
        selection: TextSelection.collapsed(offset: digits.length),
      );
    }
    if (_error != null) setState(() => _error = null);
    setState(() {});
    if (digits.length == 6) _verify();
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final otp = _otpCtrl.text;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 24, 24, 32),
            decoration: const BoxDecoration(gradient: AppColors.farmerGradient),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: r.rs(38), height: 38,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(r.rs(10))),
                    child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: r.sp(20)),
                  ),
                ),
                SizedBox(height: r.rh(24)),
                Text('📱', style: TextStyle(fontSize: r.sp(40))),
                SizedBox(height: r.rh(12)),
                Text('Verify your number',
                    style: GoogleFonts.spaceGrotesk(fontSize: r.sp(26), fontWeight: FontWeight.w700, color: Colors.white)),
                SizedBox(height: r.rh(4)),
                Text('OTP sent to ${widget.phone}',
                    style: GoogleFonts.inter(fontSize: r.sp(14), color: Colors.white.withValues(alpha: 0.8))),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Transform.translate(
                offset: const Offset(0, -20),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: r.rs(20)),
                  padding: EdgeInsets.all(r.rs(28)),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(r.rs(24)),
                    boxShadow: AppColors.deepShadow,
                  ),
                  child: Column(
                    children: [
                      Text('Enter OTP', style: GoogleFonts.spaceGrotesk(fontSize: r.sp(20), fontWeight: FontWeight.w700, color: AppColors.ink)),
                      SizedBox(height: r.rh(8)),
                      Text('6-digit code sent via SMS', style: GoogleFonts.inter(fontSize: r.sp(13), color: AppColors.muted)),
                      SizedBox(height: r.rh(32)),

                      // Hidden input + visual boxes
                      Stack(
                        children: [
                          Opacity(
                            opacity: 0.01,
                            child: TextField(
                              controller: _otpCtrl,
                              focusNode: _focusNode,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.oneTimeCode],
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                              onChanged: _onOtpChanged,
                              onSubmitted: (_) => _verify(),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _focusNode.requestFocus(),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(6, (i) {
                                final char = i < otp.length ? otp[i] : '';
                                final isActive = i == otp.length || (otp.length == 6 && i == 5);
                                return Container(
                                  width: r.rs(48),
                                  height: r.rh(56),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: _error != null
                                          ? AppColors.danger
                                          : (isActive ? AppColors.farmerAccent : AppColors.border),
                                      width: isActive ? 2 : 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(r.rs(14)),
                                    color: AppColors.surface,
                                  ),
                                  child: Text(
                                    char,
                                    style: GoogleFonts.spaceGrotesk(fontSize: r.sp(24), fontWeight: FontWeight.w700, color: AppColors.ink),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),

                      if (_error != null) ...[
                        SizedBox(height: r.rh(16)),
                        Container(
                          padding: EdgeInsets.all(r.rs(12)),
                          decoration: BoxDecoration(color: AppColors.dangerTint, borderRadius: BorderRadius.circular(r.rs(10))),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline_rounded, color: AppColors.danger, size: r.sp(16)),
                              SizedBox(width: r.rs(8)),
                              Expanded(child: Text(_error!, style: GoogleFonts.inter(fontSize: r.sp(13), color: AppColors.danger))),
                            ],
                          ),
                        ),
                      ],

                      SizedBox(height: r.rh(32)),
                      AppButton(
                        label: 'Verify & Continue',
                        onTap: _verify,
                        isLoading: _isLoading,
                        color: AppColors.farmerAccent,
                        icon: Icons.verified_outlined,
                      ),
                      SizedBox(height: r.rh(20)),
                      if (_resendSeconds > 0)
                        Text('Resend OTP in ${_resendSeconds}s',
                            style: GoogleFonts.inter(fontSize: r.sp(13), color: AppColors.muted))
                      else
                        GestureDetector(
                          onTap: _resend,
                          child: Text('Resend code',
                              style: GoogleFonts.inter(fontSize: r.sp(13), fontWeight: FontWeight.w600, color: AppColors.farmerAccent)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
