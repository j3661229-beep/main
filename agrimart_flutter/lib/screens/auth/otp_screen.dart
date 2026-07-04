import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../data/providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;
  final String role;
  final String language;
  const OtpScreen({super.key, required this.phone, required this.role, required this.language});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _ctrls = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(4, (_) => FocusNode());
  bool _isLoading = false;
  String? _error;
  int _resendSeconds = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) => _nodes[0].requestFocus());
  }

  void _startTimer() {
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
    for (final c in _ctrls) c.dispose();
    for (final n in _nodes) n.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String get _otp => _ctrls.map((c) => c.text).join();

  void _onChanged(int index, String val) {
    if (val.length == 1 && index < 3) {
      _nodes[index + 1].requestFocus();
    } else if (val.isEmpty && index > 0) {
      _nodes[index - 1].requestFocus();
    }
    if (_otp.length == 4) _verify();
  }

  Future<void> _verify() async {
    if (_otp.length < 4) {
      setState(() => _error = 'Enter the 4-digit OTP');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      await ref.read(authProvider.notifier).verifyOTP(
        phone: widget.phone,
        otp: _otp,
        role: widget.role,
        language: widget.language,
      );
      // Router will handle redirect based on auth state
    } catch (e) {
      for (final c in _ctrls) c.clear();
      _nodes[0].requestFocus();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
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
                    width: 38, height: 38,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('📱', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                Text('Verify your number',
                    style: GoogleFonts.spaceGrotesk(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 4),
                Text('OTP sent to ${widget.phone}',
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withValues(alpha: 0.8))),
              ],
            ),
          ),

          // Card
          Expanded(
            child: SingleChildScrollView(
              child: Transform.translate(
                offset: const Offset(0, -20),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AppColors.deepShadow,
                  ),
                  child: Column(
                    children: [
                      Text('Enter OTP', style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink)),
                      const SizedBox(height: 8),
                      Text('4-digit code sent via SMS', style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted)),
                      const SizedBox(height: 32),

                      // OTP boxes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(4, (i) => _OtpBox(
                          controller: _ctrls[i],
                          focusNode: _nodes[i],
                          onChanged: (v) => _onChanged(i, v),
                          hasError: _error != null,
                        )),
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.dangerTint, borderRadius: BorderRadius.circular(10)),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_error!, style: GoogleFonts.inter(fontSize: 13, color: AppColors.danger))),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),
                      AppButton(
                        label: 'Verify & Continue',
                        onTap: _verify,
                        isLoading: _isLoading,
                        color: AppColors.farmerAccent,
                        icon: Icons.verified_outlined,
                      ),
                      const SizedBox(height: 20),

                      // Resend
                      if (_resendSeconds > 0)
                        Text('Resend OTP in ${_resendSeconds}s',
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted))
                      else
                        GestureDetector(
                          onTap: _resend,
                          child: Text('Resend code',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.farmerAccent)),
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

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final void Function(String) onChanged;
  final bool hasError;

  const _OtpBox({required this.controller, required this.focusNode, required this.onChanged, required this.hasError});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64, height: 64,
      decoration: BoxDecoration(
        border: Border.all(
          color: hasError ? AppColors.danger : (focusNode.hasFocus ? AppColors.farmerAccent : AppColors.border),
          width: focusNode.hasFocus ? 2 : 1.5,
        ),
        borderRadius: BorderRadius.circular(14),
        color: AppColors.surface,
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(1)],
        style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.ink),
        decoration: const InputDecoration(border: InputBorder.none, counterText: ''),
        onChanged: onChanged,
      ),
    );
  }
}

