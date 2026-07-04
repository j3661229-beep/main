import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/agri_ui.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../core/constants/app_constants.dart';
import '../../data/providers/app_providers.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/services/api_service.dart';

class PriceAlertsScreen extends ConsumerStatefulWidget {
  const PriceAlertsScreen({super.key});

  @override
  ConsumerState<PriceAlertsScreen> createState() => _PriceAlertsScreenState();
}

class _PriceAlertsScreenState extends ConsumerState<PriceAlertsScreen> {
  final _cropCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _cropCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _createAlert() async {
    final crop = _cropCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim());
    if (crop.isEmpty || price == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter crop name and target price')));
      return;
    }
    setState(() => _saving = true);
    try {
      await ApiService.instance.createPriceAlert(cropName: crop, targetPrice: price);
      _cropCtrl.clear();
      _priceCtrl.clear();
      ref.invalidate(priceAlertsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alert set! We\'ll notify you when mandi price crosses your target.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final alerts = ref.watch(priceAlertsProvider);
    final district = ref.watch(authProvider).user?.effectiveDistrict ?? 'Nashik';

    return AgriScreen(
      title: 'Price Alerts',
      subtitle: 'Mandi price notifications',
      emoji: '🔔',
      onRefresh: () async => ref.invalidate(priceAlertsProvider),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InfoBanner(
              text: 'Get notified when mandi price in $district crosses your target (checked hourly).',
              accent: AppColors.warning,
              tint: AppColors.warningTint,
              icon: Icons.notifications_active_outlined,
            ),
            const SizedBox(height: 24),
            Text('New alert', style: GoogleFonts.spaceGrotesk(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            AgriCard(
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Crop',
                      prefixIcon: Icon(Icons.grass_outlined),
                      border: InputBorder.none,
                    ),
                    items: AppConstants.popularCrops
                        .map((c) => DropdownMenuItem(value: c['name'], child: Text(c['name']!)))
                        .toList(),
                    onChanged: (v) => _cropCtrl.text = v ?? '',
                  ),
                  const Divider(height: 1),
                  TextField(
                    controller: _priceCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    decoration: const InputDecoration(
                      labelText: 'Target price (₹/quintal)',
                      prefixText: '₹ ',
                      border: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Set Alert',
              onTap: _createAlert,
              isLoading: _saving,
              color: AppColors.farmerAccent,
              icon: Icons.notifications_active_outlined,
            ),
            const SizedBox(height: 28),
            Text('Your alerts', style: GoogleFonts.spaceGrotesk(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            alerts.when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
              error: (e, _) => Text('Could not load alerts: $e'),
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyState(
                    emoji: '🔔',
                    title: 'No alerts yet',
                    subtitle: 'Set a target price for onion, tomato, or any crop',
                  );
                }
                return Column(
                  children: list.map((a) {
                    final map = a as Map;
                    final active = map['isActive'] != false;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AgriListTile(
                        emoji: active ? '🎯' : '✅',
                        title: map['cropName'] ?? '',
                        subtitle: 'Target: ₹${map['targetPrice']}/quintal',
                        trailing: active
                            ? IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                                onPressed: () async {
                                  await ApiService.instance.deletePriceAlert(map['id'].toString());
                                  ref.invalidate(priceAlertsProvider);
                                },
                              )
                            : const BadgeChip(label: 'Triggered'),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
