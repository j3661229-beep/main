import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class ManageRatesScreen extends ConsumerStatefulWidget {
  const ManageRatesScreen({super.key});
  @override
  ConsumerState<ManageRatesScreen> createState() => _ManageRatesScreenState();
}

class _ManageRatesScreenState extends ConsumerState<ManageRatesScreen> {
  final _cropCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  Future<void> _updateRate() async {
    if (_cropCtrl.text.isEmpty || _priceCtrl.text.isEmpty) return;
    
    try {
      // Mocking the API call for now to demonstrate UI
      // await ref.read(apiServiceProvider).updateDealerRate(...);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rate updated successfully!'), backgroundColor: AppColors.success)
      );
      _cropCtrl.clear();
      _priceCtrl.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          Text('Set the rates at which you want to buy crops from farmers today.', 
            style: AppTextStyles.bodySM.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          
          Text('Crop Name', style: AppTextStyles.labelLG),
          const SizedBox(height: 8),
          TextField(
            controller: _cropCtrl,
            decoration: const InputDecoration(hintText: 'e.g. Soyabean, Cotton, Wheat'),
          ),
          const SizedBox(height: 24),
          
          Text('Price per Quintal (₹)', style: AppTextStyles.labelLG),
          const SizedBox(height: 8),
          TextField(
            controller: _priceCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'e.g. 4500'),
          ),
          const SizedBox(height: 40),
          
          ElevatedButton(
            onPressed: _updateRate,
            child: const Text('Broadcast New Rate 📢'),
          ),
          
          const SizedBox(height: 48),
          Text('Your Active Rates', style: AppTextStyles.headingMD),
          const SizedBox(height: 16),
          _buildActiveRatesList(),
        ],
      ),
    );
  }

  Widget _buildActiveRatesList() {
    // This would normally be a ref.watch(dealerRatesProvider)
    return Column(
      children: [
        _RateTile(crop: 'Soyabean', price: '4,850', date: 'Updated 2h ago'),
        _RateTile(crop: 'Cotton', price: '7,200', date: 'Updated 5h ago'),
        _RateTile(crop: 'Wheat', price: '2,400', date: 'Updated Yesterday'),
      ],
    );
  }
}

class _RateTile extends StatelessWidget {
  final String crop, price, date;
  const _RateTile({required this.crop, required this.price, required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(12)),
            child: const Text('🌾', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(crop, style: AppTextStyles.headingMD),
                Text(date, style: AppTextStyles.caption),
              ],
            ),
          ),
          Text('₹$price', style: AppTextStyles.priceSmall.copyWith(color: AppColors.primary, fontSize: 18)),
        ],
      ),
    );
  }
}
