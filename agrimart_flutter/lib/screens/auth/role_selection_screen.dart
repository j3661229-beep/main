import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Logo
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(color: AppColors.amberLight, borderRadius: BorderRadius.circular(22)),
                  child: const Center(child: Text('🌾', style: TextStyle(fontSize: 40))),
                ),
                const SizedBox(height: 20),
                const Text('AgriMart', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 8),
                Text('तुम्ही कोण आहात?', style: TextStyle(fontSize: 17, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Text('Select your role to continue', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5))),
                const Spacer(),
                // Farmer card
                _RoleCard(
                  emoji: '👨‍🌾',
                  title: 'शेतकरी',
                  subtitle: 'Farmer',
                  description: 'Buy seeds, fertilizers, pesticides at best prices',
                  color: AppColors.primaryLight,
                  onTap: () => context.push('/auth/login?role=FARMER'),
                ),
                const SizedBox(height: 16),
                // Dealer card
                _RoleCard(
                  emoji: '🤝',
                  title: 'व्यापारी',
                  subtitle: 'Dealer',
                  description: 'Buy crops directly from farmers at your rates',
                  color: Colors.blueAccent,
                  onTap: () => context.push('/auth/login?role=DEALER'),
                ),
                const SizedBox(height: 16),
                // Supplier card
                _RoleCard(
                  emoji: '🏪',
                  title: 'पुरवठादार',
                  subtitle: 'Supplier',
                  description: 'Sell agricultural inputs directly to farmers',
                  color: AppColors.amber,
                  onTap: () => context.push('/auth/login?role=SUPPLIER'),
                ),
                const Spacer(),
                Text('AgriMart v1.0 · Made for Indian Farmers 🇮🇳',
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.3)), textAlign: TextAlign.center),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String emoji, title, subtitle, description;
  final Color color;
  final VoidCallback onTap;
  const _RoleCard({required this.emoji, required this.title, required this.subtitle, required this.description, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(width: 8),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5))),
                ]),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.65))),
              ]),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }
}
