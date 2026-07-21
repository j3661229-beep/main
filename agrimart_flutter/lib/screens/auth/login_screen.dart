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

/// Farmer-only login — OTP via mobile number (v1).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locale = ref.read(localeProvider);
      if (!IndianLanguages.isSupported(locale.languageCode)) {
        ref.read(localeProvider.notifier).setLocale(const Locale('en'));
      }
    });
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });

    try {
      await ref.read(authProvider.notifier).sendOTP(
        phone: '+91${_phoneCtrl.text.trim()}',
        role: 'FARMER',
      );
      if (mounted) {
        final lang = ref.read(localeProvider).languageCode;
        context.push(
          '/auth/otp?phone=${Uri.encodeComponent('+91${_phoneCtrl.text.trim()}')}&role=FARMER&language=$lang',
        );
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final locale = ref.watch(localeProvider);
    final selectedLang = locale.languageCode;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 24, 24, 32),
              decoration: const BoxDecoration(gradient: AppColors.farmerGradient),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomPaint(
                    size: const Size(70, 70),
                    painter: _DashedCirclePainter(color: Colors.white.withValues(alpha: 0.6)),
                    child: Container(
                      width: r.rs(70),
                      height: r.rh(70),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                      child: Center(child: Text('🌾', style: TextStyle(fontSize: r.sp(32)))),
                    ),
                  ),
                  SizedBox(height: r.rh(16)),
                  Text(
                    'Namaste 🙏',
                    style: GoogleFonts.spaceGrotesk(fontSize: r.sp(28), fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  SizedBox(height: r.rh(4)),
                  Text(
                    'Sign in with your mobile number',
                    style: GoogleFonts.inter(fontSize: r.sp(14), color: Colors.white.withValues(alpha: 0.85)),
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: r.rs(20)),
                padding: EdgeInsets.all(r.rs(24)),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(r.rs(24)),
                  boxShadow: AppColors.deepShadow,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _LangChip(label: 'English', code: 'en', selected: selectedLang, onTap: (c) => ref.read(localeProvider.notifier).setLocale(Locale(c))),
                          SizedBox(width: r.rs(8)),
                          _LangChip(label: 'हिंदी', code: 'hi', selected: selectedLang, onTap: (c) => ref.read(localeProvider.notifier).setLocale(Locale(c))),
                          SizedBox(width: r.rs(8)),
                          _LangChip(label: 'मराठी', code: 'mr', selected: selectedLang, onTap: (c) => ref.read(localeProvider.notifier).setLocale(Locale(c))),
                        ],
                      ),
                      SizedBox(height: r.rh(20)),
                      Text('Mobile Number', style: GoogleFonts.inter(fontSize: r.sp(13), fontWeight: FontWeight.w500, color: AppColors.muted)),
                      SizedBox(height: r.rh(6)),
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                        decoration: InputDecoration(
                          hintText: '9876543210',
                          prefixIcon: Container(
                            margin: EdgeInsets.all(r.rs(12)),
                            padding: EdgeInsets.symmetric(horizontal: r.rs(10), vertical: r.rh(6)),
                            decoration: BoxDecoration(color: AppColors.farmerTint, borderRadius: BorderRadius.circular(r.rs(8))),
                            child: Text('+91', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, color: AppColors.farmerAccent, fontSize: r.sp(13))),
                          ),
                          prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: r.rh(0)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(r.rs(12)),
                            borderSide: const BorderSide(color: AppColors.farmerAccent, width: 2),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter your mobile number';
                          if (v.length != 10) return 'Enter a valid 10-digit number';
                          return null;
                        },
                      ),
                      if (_error != null) ...[
                        SizedBox(height: r.rh(12)),
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
                      SizedBox(height: r.rh(24)),
                      AppButton(
                        label: 'Send OTP',
                        onTap: _submit,
                        isLoading: _isLoading,
                        color: AppColors.farmerAccent,
                        icon: Icons.sms_outlined,
                      ),
                      SizedBox(height: r.rh(16)),
                      Center(
                        child: Text(
                          '🇮🇳  Built for Indian farmers',
                          style: GoogleFonts.inter(fontSize: r.sp(12), color: AppColors.muted.withValues(alpha: 0.8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label, code, selected;
  final void Function(String) onTap;
  const _LangChip({required this.label, required this.code, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final isSel = code == selected;
    return GestureDetector(
      onTap: () => onTap(code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: r.rs(14), vertical: r.rh(7)),
        decoration: BoxDecoration(
          color: isSel ? AppColors.farmerTint : AppColors.surface,
          border: Border.all(color: isSel ? AppColors.farmerAccent : AppColors.border, width: isSel ? 1.5 : 1),
          borderRadius: BorderRadius.circular(r.rs(20)),
        ),
        child: Text(label, style: GoogleFonts.inter(fontSize: r.sp(12), fontWeight: isSel ? FontWeight.w600 : FontWeight.w400, color: isSel ? AppColors.farmerAccent : AppColors.muted)),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  _DashedCirclePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 2..style = PaintingStyle.stroke;
    const count = 20;
    const da = 2 * 3.14159265 / count;
    final radius = size.width / 2 - 3;
    final center = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i < count; i++) {
      final start = (i * da) - 3.14159265 / 2;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, da * 0.55, false, paint);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}
