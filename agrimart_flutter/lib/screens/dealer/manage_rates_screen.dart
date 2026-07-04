import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/app_providers.dart';
import '../../data/services/api_service.dart';

class ManageRatesScreen extends ConsumerStatefulWidget {
  const ManageRatesScreen({super.key});
  @override
  ConsumerState<ManageRatesScreen> createState() => _ManageRatesScreenState();
}

class _ManageRatesScreenState extends ConsumerState<ManageRatesScreen> {
  final _cropCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _updateRate() async {
    if (_cropCtrl.text.isEmpty || _priceCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      await ApiService.instance.updateDealerRate({
        'cropName': _cropCtrl.text.trim(),
        'pricePerQuintal': double.parse(_priceCtrl.text.trim()),
      });
      _cropCtrl.clear();
      _priceCtrl.clear();
      ref.invalidate(dealerRatesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rate updated successfully!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rates = ref.watch(dealerRatesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Buying Rates'),
        backgroundColor: AppColors.primary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Update Daily Prices', style: AppTextStyles.headingLG),
          const SizedBox(height: 8),
          Text(
            'Set the rates at which you want to buy crops from farmers today.',
            style: AppTextStyles.bodySM.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          Text('Crop Name', style: AppTextStyles.labelLG),
          const SizedBox(height: 8),
          TextField(controller: _cropCtrl, decoration: const InputDecoration(hintText: 'e.g. Onion, Soybean')),
          const SizedBox(height: 24),
          Text('Price per Quintal (₹)', style: AppTextStyles.labelLG),
          const SizedBox(height: 8),
          TextField(controller: _priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'e.g. 4500')),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _loading ? null : _updateRate,
            child: _loading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Broadcast New Rate 📢'),
          ),
          const SizedBox(height: 48),
          Text('Your Active Rates', style: AppTextStyles.headingMD),
          const SizedBox(height: 16),
          rates.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (list) {
              if (list.isEmpty) {
                return const Text('No rates set yet. Add your first buying rate above.');
              }
              return Column(
                children: list.map((r) {
                  final rate = r as Map;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(rate['cropName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${rate['district'] ?? ''} • ${rate['isActive'] == false ? 'Inactive' : 'Active'}'),
                    trailing: Text('₹${rate['pricePerQuintal']}/qtl', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
