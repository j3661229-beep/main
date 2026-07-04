// Legacy PhoneScreen — redirected to the unified LoginScreen
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PhoneScreen extends StatelessWidget {
  final String role;
  const PhoneScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    // Immediately redirect to the new login flow
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.go('/auth/login?role=$role');
    });
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
