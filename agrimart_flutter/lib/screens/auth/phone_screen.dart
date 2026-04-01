import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class PhoneScreen extends ConsumerStatefulWidget {
  final String role;
  const PhoneScreen({super.key, required this.role});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _phoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() { _phoneCtrl.dispose(); super.dispose(); }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await ref.read(authProvider.notifier).sendOTP(_phoneCtrl.text.trim(), widget.role);
      if (mounted) {
        context.push('/auth/otp', extra: {'phone': _phoneCtrl.text.trim(), 'role': widget.role});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _googleLogin() async {
    try {
      final user = await ref.read(authProvider.notifier).signInWithGoogle(widget.role);
      // The GoRouter automatically redirects the user if user.isVerified is true.
      // If it's false, the router redirects them to /auth/setup.
      if (user != null && mounted) {
          if (user.isVerified) {
             context.go(user.isFarmer ? '/farmer' : '/supplier');
          } else {
             context.go('/auth/setup');
          }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In failed: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isFarmer = widget.role == 'FARMER';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Back + title
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(children: [
                  GestureDetector(onTap: () => context.pop(), child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white)),
                  const SizedBox(width: 12),
                  Text(isFarmer ? '👨‍🌾 शेतकरी Login' : '🏪 Supplier Login',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                ]),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                  ),
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const SizedBox(height: 16),
                      Text('मोबाईल नंबर', style: AppTextStyles.headingLG.copyWith(color: AppColors.primary)),
                      const SizedBox(height: 4),
                      const Text('Your WhatsApp OTP will be sent to this number', style: AppTextStyles.bodySM),
                      const SizedBox(height: 28),
                      // Phone input
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          counterText: '',
                          prefixIcon: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Text('🇮🇳', style: TextStyle(fontSize: 20)),
                              const SizedBox(width: 8),
                              Text('+91', style: AppTextStyles.headingSM.copyWith(color: AppColors.primary)),
                              const SizedBox(width: 8),
                              Container(height: 24, width: 1, color: AppColors.border),
                              const SizedBox(width: 8),
                            ]),
                          ),
                          hintText: '99999 99999',
                          hintStyle: AppTextStyles.bodyLG.copyWith(color: AppColors.textTertiary),
                        ),
                        style: AppTextStyles.headingLG.copyWith(letterSpacing: 2),
                        validator: (v) => v == null || v.length != 10 ? 'Enter valid 10-digit mobile number' : null,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.amberSurface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.amberLight)),
                        child: Row(children: [
                          const Text('💬', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          const Expanded(child: Text('OTP will be sent via WhatsApp', style: AppTextStyles.bodySM)),
                        ]),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: auth.isLoading ? null : _sendOTP,
                          child: auth.isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Send WhatsApp OTP 📲', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('OR', style: TextStyle(color: AppColors.textTertiary, fontWeight: FontWeight.bold))),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton(
                          onPressed: auth.isLoading ? null : _googleLogin,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.network('https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg', width: 24, height: 24),
                              const SizedBox(width: 12),
                              const Text('Continue with Google', style: TextStyle(fontSize: 16, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
