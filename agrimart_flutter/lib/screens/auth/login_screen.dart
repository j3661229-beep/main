import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../data/providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String role;
  const LoginScreen({super.key, required this.role});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _formKey   = GlobalKey<FormState>();
  String _language = 'en';
  bool _obscurePass = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _error;

  bool get _isFarmer => widget.role == 'FARMER';

  Color get _accent => AppColors.accentFor(widget.role);
  Color get _tint   => AppColors.tintFor(widget.role);
  LinearGradient get _gradient => AppColors.gradientFor(widget.role);

  String get _roleLabel {
    switch (widget.role) {
      case 'SUPPLIER': return 'Supplier';
      case 'DEALER':   return 'Dealer';
      default:         return 'Farmer';
    }
  }

  String get _roleEmoji {
    switch (widget.role) {
      case 'SUPPLIER': return '🏪';
      case 'DEALER':   return '🤝';
      default:         return '🌾';
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });

    try {
      if (_isFarmer) {
        await ref.read(authProvider.notifier).sendOTP(
          phone: '+91${_phoneCtrl.text.trim()}',
          role: widget.role,
        );
        if (mounted) {
          context.push('/auth/otp?phone=${Uri.encodeComponent('+91${_phoneCtrl.text.trim()}')}&role=${widget.role}&language=$_language');
        }
      } else {
        await ref.read(authProvider.notifier).loginWithPassword(
          emailOrPhone: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          role: widget.role,
        );
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleLogin() async {
    setState(() { _isGoogleLoading = true; _error = null; });
    try {
      await ref.read(authProvider.notifier).signInWithGoogle(widget.role);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authLoading = ref.watch(authProvider).isLoading;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header gradient
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 24, 24, 32),
              decoration: BoxDecoration(gradient: _gradient),
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
                  // Stamp
                  CustomPaint(
                    size: const Size(70, 70),
                    painter: _DashedCirclePainter(color: Colors.white.withValues(alpha: 0.6)),
                    child: Container(
                      width: 70, height: 70,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                      child: Center(child: Text(_roleEmoji, style: const TextStyle(fontSize: 32))),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isFarmer ? 'Namaste 🙏' : 'Welcome back',
                    style: GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sign in as $_roleLabel',
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            ),

            // Form card
            Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppColors.deepShadow,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isFarmer) ...[
                        // Language chips
                        Row(
                          children: [
                            _LangChip(label: 'English', code: 'en', selected: _language, onTap: (c) => setState(() => _language = c)),
                            const SizedBox(width: 8),
                            _LangChip(label: 'हिंदी', code: 'hi', selected: _language, onTap: (c) => setState(() => _language = c)),
                            const SizedBox(width: 8),
                            _LangChip(label: 'मराठी', code: 'mr', selected: _language, onTap: (c) => setState(() => _language = c)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Phone field
                        Text('Mobile Number', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.muted)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                          decoration: InputDecoration(
                            hintText: '9876543210',
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(12),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: _tint, borderRadius: BorderRadius.circular(8)),
                              child: Text('+91', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, color: _accent, fontSize: 13)),
                            ),
                            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _accent, width: 2),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Enter your mobile number';
                            if (v.length != 10) return 'Enter a valid 10-digit number';
                            return null;
                          },
                        ),
                      ] else ...[
                        // Email/Phone
                        Text('Email or Phone', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.muted)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'business@example.com',
                            prefixIcon: Icon(Icons.person_outline_rounded, color: _accent, size: 20),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _accent, width: 2)),
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? 'Enter email or phone' : null,
                        ),
                        const SizedBox(height: 16),
                        // Password
                        Text('Password', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.muted)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: _obscurePass,
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            prefixIcon: Icon(Icons.lock_outline_rounded, color: _accent, size: 20),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _obscurePass = !_obscurePass),
                              icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.muted, size: 20),
                            ),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _accent, width: 2)),
                          ),
                          validator: (v) => (v == null || v.length < 6) ? 'Enter your password' : null,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: Text('Forgot password?', style: GoogleFonts.inter(fontSize: 13, color: _accent)),
                          ),
                        ),
                      ],

                      if (_error != null) ...[
                        const SizedBox(height: 12),
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

                      const SizedBox(height: 24),
                      AppButton(
                        label: _isFarmer ? 'Send OTP' : 'Log In',
                        onTap: _submit,
                        isLoading: _isLoading,
                        color: _accent,
                        icon: _isFarmer ? Icons.sms_outlined : Icons.login_rounded,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Expanded(child: Divider(color: AppColors.border)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('or', style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
                          ),
                          const Expanded(child: Divider(color: AppColors.border)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: (_isLoading || _isGoogleLoading || authLoading) ? null : _googleLogin,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: AppColors.surface,
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isGoogleLoading
                              ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: _accent))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.g_mobiledata_rounded, color: _accent, size: 28),
                                    const SizedBox(width: 10),
                                    Text(
                                      l10n.loginWithGoogle,
                                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Don't have an account? ", style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted)),
                          GestureDetector(
                            onTap: () => context.push('/auth/signup?role=${widget.role}'),
                            child: Text('Sign Up', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _accent)),
                          ),
                        ],
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
    final isSel = code == selected;
    return GestureDetector(
      onTap: () => onTap(code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSel ? AppColors.farmerTint : AppColors.surface,
          border: Border.all(color: isSel ? AppColors.farmerAccent : AppColors.border, width: isSel ? 1.5 : 1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: isSel ? FontWeight.w600 : FontWeight.w400, color: isSel ? AppColors.farmerAccent : AppColors.muted)),
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
    final r = size.width / 2 - 3;
    final c = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i < count; i++) {
      final s = (i * da) - 3.14159265 / 2;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), s, da * 0.55, false, paint);
    }
  }
  @override bool shouldRepaint(_) => false;
}



