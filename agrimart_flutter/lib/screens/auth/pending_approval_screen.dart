import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';

class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.r;
    final auth = ref.watch(authProvider);
    final role = auth.user?.role ?? 'SUPPLIER';
    final isDealer = role == 'DEALER';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1976D2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top decorative orbs
              SizedBox(height: r.rh(200),
                child: Stack(
                  children: [
                    Positioned(
                      top: -40,
                      right: -40,
                      child: Container(
                        width: r.rs(200),
                        height: r.rh(200),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 20,
                      left: -60,
                      child: Container(
                        width: r.rs(160),
                        height: r.rh(160),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.07),
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: r.rs(100),
                            height: r.rh(100),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                            ),
                            child: Center(
                              child: Text('⏳', style: TextStyle(fontSize: r.sp(48))),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Main card
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  padding: EdgeInsets.all(r.rs(32)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: r.rh(8)),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: r.rs(16), vertical: r.rh(6)),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(r.rs(20)),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Text(
                          '📋 VERIFICATION PENDING',
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.w800,
                            fontSize: r.sp(11),
                            letterSpacing: 1,
                          ),
                        ),
                      ),

                      SizedBox(height: r.rh(24)),
                      Text(
                        isDealer ? 'Dealer Account\nUnder Review' : 'Supplier Account\nUnder Review',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: r.sp(28),
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                          height: r.rh(1.2),
                        ),
                      ),

                      SizedBox(height: r.rh(16)),
                      Text(
                        'Your government document has been submitted successfully. Our team will verify your account within 24–48 hours.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: r.sp(15),
                          color: AppColors.textSecondary,
                          height: r.rh(1.6),
                        ),
                      ),

                      SizedBox(height: r.rh(32)),

                      // Steps
                      _StepTile(
                        icon: '✅',
                        title: 'Document Submitted',
                        subtitle: 'Your govt document is uploaded',
                        done: true,
                      ),
                      SizedBox(height: r.rh(12)),
                      _StepTile(
                        icon: '🔍',
                        title: 'Admin Review',
                        subtitle: 'Our team is reviewing your documents',
                        done: false,
                        active: true,
                      ),
                      SizedBox(height: r.rh(12)),
                      _StepTile(
                        icon: '🎉',
                        title: 'Account Activated',
                        subtitle: 'You\'ll get notified when approved',
                        done: false,
                      ),

                      const Spacer(),

                      Container(
                        padding: EdgeInsets.all(r.rs(16)),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(r.rs(20)),
                          border: Border.all(color: AppColors.primaryBorder.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: r.rs(40),
                              height: r.rh(40),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(r.rs(12)),
                              ),
                              child: Center(child: Text('📱', style: TextStyle(fontSize: r.sp(20)))),
                            ),
                            SizedBox(width: r.rs(12)),
                            Expanded(
                              child: Text(
                                'You\'ll receive a WhatsApp notification once your account is approved.',
                                style: TextStyle(fontSize: r.sp(12), color: AppColors.textSecondary, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: r.rh(20)),

                      SizedBox(
                        width: double.infinity,
                        height: r.rh(54),
                        child: OutlinedButton(
                          onPressed: () => ref.read(authProvider.notifier).logout(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.rs(16))),
                          ),
                          child: Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700, fontSize: r.sp(16))),
                        ),
                      ),

                      SizedBox(height: r.rh(8)),
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

class _StepTile extends StatelessWidget {
  final String icon, title, subtitle;
  final bool done, active;
  const _StepTile({required this.icon, required this.title, required this.subtitle, this.done = false, this.active = false});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Container(
      padding: EdgeInsets.all(r.rs(16)),
      decoration: BoxDecoration(
        color: done ? Colors.green.shade50 : active ? AppColors.primarySurface : AppColors.surface,
        borderRadius: BorderRadius.circular(r.rs(16)),
        border: Border.all(
          color: done ? Colors.green.shade200 : active ? AppColors.primaryBorder : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Text(icon, style: TextStyle(fontSize: r.sp(24))),
          SizedBox(width: r.rs(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: r.sp(13),
                  color: done ? Colors.green.shade800 : active ? AppColors.primary : AppColors.textPrimary,
                )),
                Text(subtitle, style: TextStyle(fontSize: r.sp(11), color: AppColors.textTertiary)),
              ],
            ),
          ),
          if (done) Icon(Icons.check_circle_rounded, color: Colors.green, size: r.sp(20)),
          if (active) SizedBox(width: r.rs(18),
            height: r.rh(18),
            child: CircularProgressIndicator(strokeWidth: r.rs(2), color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}



