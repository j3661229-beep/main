import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String role;
  const LoginScreen({super.key, required this.role});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _phoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = ref.read(authProvider);
    if (auth.isLoading) return;
    try {
      await ref.read(authProvider.notifier).sendOTP(_phoneCtrl.text.trim(), widget.role);
      if (mounted) {
        context.push('/auth/otp', extra: {'phone': _phoneCtrl.text.trim(), 'role': widget.role});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _googleSignIn() async {
    try {
      final user = await ref.read(authProvider.notifier).signInWithGoogle(widget.role);
      if (user != null && mounted) {
        if (user.isVerified) {
          if (user.isDealer) return context.go('/dealer');
          if (user.isFarmer) return context.go('/farmer');
          return context.go('/supplier');
        }
        context.go('/auth/setup');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isFarmer = widget.role == 'FARMER';
    final isDealer = widget.role == 'DEALER';

    final String emoji = isFarmer ? '🌽' : isDealer ? '💰' : '📦';
    final String titleStr = isFarmer ? '👨‍🌾 शेतकरी Login' : isDealer ? '🤝 Dealer Login' : '🏪 Supplier Login';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Back Button & Title
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Text(titleStr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                  ],
                ),
              ),

              // Branding
              Container(
                padding: const EdgeInsets.fromLTRB(32, 8, 32, 24),
                child: Column(children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Center(child: Text(emoji, style: const TextStyle(fontSize: 46))),
                  ),
                  const SizedBox(height: 16),
                  const Text('Welcome to AgriMart',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text(
                    'Sign in to continue as ${widget.role.toLowerCase()}',
                    style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7), fontWeight: FontWeight.w500),
                  ),
                ]),
              ),

              // Login cards panel
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(36), topRight: Radius.circular(36)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      // Tab bar
                      Container(
                        margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelColor: Colors.white,
                          unselectedLabelColor: AppColors.textSecondary,
                          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          tabs: const [
                            Tab(text: '📱 Mobile OTP'),
                            Tab(text: '🔵 Google'),
                          ],
                        ),
                      ),

                      // Tab content
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // ── OTP Tab ──
                            SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Mobile Number', style: AppTextStyles.labelLG),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _phoneCtrl,
                                      keyboardType: TextInputType.phone,
                                      maxLength: 10,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      decoration: InputDecoration(
                                        counterText: '',
                                        prefixIcon: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14),
                                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                                            const Text('🇮🇳', style: TextStyle(fontSize: 18)),
                                            const SizedBox(width: 6),
                                            Text('+91', style: AppTextStyles.headingSM.copyWith(color: AppColors.primary)),
                                            const SizedBox(width: 6),
                                            Container(height: 22, width: 1, color: AppColors.border),
                                            const SizedBox(width: 6),
                                          ]),
                                        ),
                                        hintText: '99999 99999',
                                      ),
                                      style: AppTextStyles.headingLG.copyWith(letterSpacing: 2),
                                      validator: (v) => v == null || v.length != 10 ? 'Enter valid 10-digit number' : null,
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.amberSurface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.amberLight),
                                      ),
                                      child: const Row(children: [
                                        Text('💬', style: TextStyle(fontSize: 16)),
                                        SizedBox(width: 10),
                                        Expanded(child: Text('OTP will be sent via WhatsApp', style: AppTextStyles.bodySM)),
                                      ]),
                                    ),
                                    const SizedBox(height: 28),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 56,
                                      child: ElevatedButton(
                                        onPressed: auth.isLoading ? null : _sendOTP,
                                        style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                                        child: auth.isLoading
                                            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                            : const Text('Send WhatsApp OTP 📲', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // ── Google Tab ──
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                                    ),
                                    child: Column(
                                      children: [
                                        const Text('🔐', style: TextStyle(fontSize: 48)),
                                        const SizedBox(height: 12),
                                        const Text('Sign in with Google',
                                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Quick and secure sign-in using\nyour Google account',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 28),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 58,
                                    child: ElevatedButton(
                                      onPressed: auth.isLoading ? null : _googleSignIn,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: AppColors.textPrimary,
                                        elevation: 0,
                                        side: const BorderSide(color: AppColors.border),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      ),
                                      child: auth.isLoading
                                          ? const CircularProgressIndicator()
                                          : Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Image.network(
                                                  'https://www.gstatic.com/images/branding/product/1x/gsa_512dp.png',
                                                  width: 24, height: 24,
                                                  errorBuilder: (_, __, ___) => const Icon(Icons.account_circle, color: Colors.grey),
                                                ),
                                                const SizedBox(width: 12),
                                                const Text('Sign in with Google',
                                                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                        child: Text(
                          'By continuing, you agree to our Terms & Privacy Policy',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                        ),
                      ),
                    ],
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
