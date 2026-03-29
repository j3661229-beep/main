// Quick stub screens for remaining routes
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/app_providers.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_fallback.dart';
import '../../core/widgets/app_shimmer.dart';

class OrderTrackingScreen extends ConsumerWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracking = ref.watch(orderTrackingProvider(orderId));
    const steps = ['Order Placed', 'Payment Confirmed', 'Processing', 'Dispatched', 'Out for Delivery', 'Delivered'];
    return Scaffold(
      appBar: AppBar(title: const Text('📍 Order Tracking'), backgroundColor: AppColors.primary),
      body: tracking.when(
        loading: () => const AppShimmerList(),
        error: (e, _) => AppErrorState(message: 'Could not load tracking details', onRetry: () => ref.invalidate(orderTrackingProvider)),
        data: (data) {
          final currentStep = data['currentStep'] as int? ?? 0;
          return ListView(padding: const EdgeInsets.all(24), children: [
            const Text('Order Status', style: AppTextStyles.headingXL),
            const SizedBox(height: 24),
            ...steps.asMap().entries.map((e) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Column(children: [
                Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, color: e.key <= currentStep ? AppColors.primary : AppColors.border), child: Icon(e.key < currentStep ? Icons.check : Icons.circle, size: 16, color: Colors.white)),
                if (e.key < steps.length - 1) Container(width: 2, height: 40, color: e.key < currentStep ? AppColors.primary : AppColors.border),
              ]),
              const SizedBox(width: 16),
              Padding(padding: const EdgeInsets.only(top: 4), child: Text(e.value, style: e.key == currentStep ? AppTextStyles.headingSM.copyWith(color: AppColors.primary) : AppTextStyles.bodyMD)),
            ])).toList(),
            const SizedBox(height: 24),
            if (data['estimatedDelivery'] != null) Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(14)),
              child: Row(children: [const Text('📅', style: TextStyle(fontSize: 24)), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Estimated Delivery', style: AppTextStyles.labelLG), Text(data['estimatedDelivery'].toString(), style: AppTextStyles.headingSM)])])),
          ]);
        },
      ),
    );
  }
}

class CropAdvisorScreen extends StatefulWidget {
  const CropAdvisorScreen({super.key});
  @override
  State<CropAdvisorScreen> createState() => _CropAdvisorState();
}

class _CropAdvisorState extends State<CropAdvisorScreen> {
  final _locCtrl = TextEditingController(text: 'Nashik');
  final _soilCtrl = TextEditingController(text: 'Black Cotton Soil');
  final _seasonCtrl = TextEditingController(text: 'Kharif');
  final _sizeCtrl = TextEditingController(text: '2');
  bool _loading = false;
  List _recommendations = [];

  Future<void> _analyze() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.instance.getCropRecommend({
        'location': _locCtrl.text,
        'soilType': _soilCtrl.text,
        'season': _seasonCtrl.text,
        'farmSize': int.tryParse(_sizeCtrl.text) ?? 2,
      });
      setState(() => _recommendations = res['crops'] ?? []);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI Error: $e'), backgroundColor: AppColors.error));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('🌱 AI Crop Advisor'), backgroundColor: AppColors.primary),
      body: _recommendations.isNotEmpty 
        ? _buildResults() 
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(16)), child: Row(children: [const Text('🌾', style: TextStyle(fontSize: 40)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Gemini AI Advisor', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), Text('Tell us about your farm setup and our AI will recommend the top high-yield crops.', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13))]))])),
              const SizedBox(height: 24),
              const Text('Farm Details', style: AppTextStyles.headingMD),
              const SizedBox(height: 16),
              _buildField('Location / District', _locCtrl),
              const SizedBox(height: 12),
              _buildField('Soil Type (e.g. Red, Black)', _soilCtrl),
              const SizedBox(height: 12),
              _buildField('Season (Kharif, Rabi, Zaid)', _seasonCtrl),
              const SizedBox(height: 12),
              _buildField('Farm Size (Acres)', _sizeCtrl, isNum: true),
              const SizedBox(height: 32),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: _loading ? null : _analyze,
                child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white)) : const Text('✨ Get AI Recommendations'),
              )),
            ]),
          ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, {bool isNum = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label, filled: true, fillColor: AppColors.surface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
    );
  }

  Widget _buildResults() {
    return Column(children: [
      Container(padding: const EdgeInsets.all(16), color: AppColors.surface, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('AI Top Recommendations', style: AppTextStyles.headingSM),
        TextButton.icon(onPressed: () => setState(() => _recommendations = []), icon: const Icon(Icons.refresh, size: 16), label: const Text('New Analysis'))
      ])),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _recommendations.length,
          itemBuilder: (ctx, i) {
            final crop = _recommendations[i];
            return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Text(crop['emoji'] ?? '🌿', style: const TextStyle(fontSize: 32)), const SizedBox(width: 12), Expanded(child: Text(crop['crop'] ?? 'Unknown', style: AppTextStyles.headingMD)), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(20)), child: Text('${crop['matchPercent']}% Match', style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 12)))]),
              const SizedBox(height: 12),
              Text(crop['reason'] ?? '', style: AppTextStyles.bodyMD),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                _statInfo('Yield', crop['expectedYield']?.toString() ?? 'N/A'),
                _statInfo('Demand', (crop['marketDemand']?.toString() ?? 'Medium').toUpperCase(), icon: '📈'),
              ]),
            ]));
          },
        ),
      ),
    ]);
  }

  Widget _statInfo(String label, String val, {String icon = '⚖️'}) => Row(children: [Text(icon, style: const TextStyle(fontSize: 16)), const SizedBox(width: 4), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)), Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))])]);
}

class MandiPricesScreen extends ConsumerWidget {
  const MandiPricesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('📈 Mandi Prices'), backgroundColor: AppColors.primary),
    body: ref.watch(mandiProvider('Nashik')).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(child: Text('Could not load prices')),
      data: (data) {
        final prices = data['prices'] as List? ?? [];
        return ListView.builder(padding: const EdgeInsets.all(16), itemCount: prices.length, itemBuilder: (ctx, i) {
          final p = prices[i] as Map;
          final up = (p['change'] as num? ?? 0) >= 0;
          return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
            child: Row(children: [
              Text(p['emoji'] as String? ?? '🌾', style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p['crop'] as String? ?? '', style: AppTextStyles.headingSM), Text('₹${p['price']}/quintal', style: AppTextStyles.priceSmall.copyWith(fontSize: 14))])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: (up ? AppColors.success : AppColors.error).withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                child: Text('${up ? '↑' : '↓'} ${(p['change'] as num? ?? 0).abs().toStringAsFixed(1)}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: up ? AppColors.success : AppColors.error))),
            ]));
        });
      },
    ),
  );
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('⚙️ Profile & Settings'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))]),
            child: Column(children: [
              CircleAvatar(radius: 40, backgroundColor: AppColors.primarySurface, child: Text(user?.isFarmer == true ? '👨‍🌾' : '🚛', style: const TextStyle(fontSize: 36))),
              const SizedBox(height: 16),
              Text(user?.name ?? 'AgriMart User', style: AppTextStyles.headingXL),
              Text(user?.phone ?? '+91 xxxxxx', style: AppTextStyles.bodyMD),
              const SizedBox(height: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)), child: Text(user?.isFarmer == true ? 'Verified Farmer' : 'Verified Supplier', style: const TextStyle(color: AppColors.primaryDark, fontSize: 12, fontWeight: FontWeight.w700))),
            ]),
          ),
          const SizedBox(height: 24),
          const Text('Account Settings', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _buildItem(Icons.language, 'Language', 'मराठी (Marathi)'),
          _buildItem(Icons.location_on_outlined, 'Farm Address', 'Manage locations'),
          _buildItem(Icons.notifications_outlined, 'Notifications', 'Manage alerts'),
          _buildItem(Icons.security, 'Privacy & Security', 'Data controls'),
          const SizedBox(height: 24),
          const Text('Support & App', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _buildItem(Icons.help_outline, 'Help Center', 'FAQs & Support'),
          _buildItem(Icons.article_outlined, 'Terms & Conditions', 'Legal agreements'),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                ref.read(authProvider.notifier).logout();
              },
              style: TextButton.styleFrom(padding: const EdgeInsets.all(16), backgroundColor: AppColors.error.withOpacity(0.1), foregroundColor: AppColors.error, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('Log Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildItem(IconData icon, String title, String sub) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: ListTile(
        leading: Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: AppColors.background, shape: BoxShape.circle), child: Icon(icon, color: AppColors.primary, size: 20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textTertiary),
      ),
    );
  }
}
