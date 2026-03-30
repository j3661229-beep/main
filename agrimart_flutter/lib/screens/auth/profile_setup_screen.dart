import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});
  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Shared
  final _nameCtrl = TextEditingController();

  // Farmer specific
  final _villageCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _farmSizeCtrl = TextEditingController();

  // Supplier specific
  final _businessNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController(); // acts as both village and full address physically
  final _mapLinkCtrl = TextEditingController(); // currently appended to address on backend or just stored safely

  @override
  void initState() {
    super.initState();
    // Pre-fill existing data from user object if any
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        _nameCtrl.text = user.name;
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _villageCtrl.dispose();
    _districtCtrl.dispose();
    _farmSizeCtrl.dispose();
    _businessNameCtrl.dispose();
    _addressCtrl.dispose();
    _mapLinkCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authProvider).user;
    if (user == null) return;

    final isFarmer = user.isFarmer;
    
    // We append the map link directly to the address text to avoid Prisma migration for now
    final supplierAddress = '${_addressCtrl.text.trim()}${_mapLinkCtrl.text.isNotEmpty ? ' | MAP: ${_mapLinkCtrl.text.trim()}' : ''}';

    final data = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      if (isFarmer) 'village': _villageCtrl.text.trim(),
      if (isFarmer) 'district': _districtCtrl.text.trim(),
      if (isFarmer) 'farmSizeAcres': _farmSizeCtrl.text.trim().isNotEmpty ? double.tryParse(_farmSizeCtrl.text.trim()) : 0,
      
      if (!isFarmer) 'businessName': _businessNameCtrl.text.trim(),
      if (!isFarmer) 'address': supplierAddress,
      if (!isFarmer) 'district': _districtCtrl.text.trim(),
    };

    try {
      await ref.read(authProvider.notifier).completeOnboarding(data);
      // Once isVerified is true, router automatically bumps us to /farmer or /supplier
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    if (user == null) return const Scaffold();

    final isFarmer = user.isFarmer;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false, // Must complete setup, no going back
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text('Welcome to AgriMart! 🎉', style: AppTextStyles.headingXL),
              const SizedBox(height: 8),
              Text(
                isFarmer 
                  ? 'Please fill in a few details about your farm to proceed.'
                  : 'Please provide your shop details so farmers can find you.',
                style: AppTextStyles.bodyMD.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),

              // Shared Field: Name
              Text('Your Full Name', style: AppTextStyles.labelLG),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(hintText: 'e.g. Ramesh Patel'),
                validator: (v) => v!.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 24),

              // Farmer Fields
              if (isFarmer) ...[
                Text('Village / Town', style: AppTextStyles.labelLG),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _villageCtrl,
                  decoration: const InputDecoration(hintText: 'e.g. Shirpur'),
                  validator: (v) => v!.isEmpty ? 'Village is required' : null,
                ),
                const SizedBox(height: 24),

                Text('District', style: AppTextStyles.labelLG),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _districtCtrl,
                  decoration: const InputDecoration(hintText: 'e.g. Dhule'),
                  validator: (v) => v!.isEmpty ? 'District is required' : null,
                ),
                const SizedBox(height: 24),

                Text('Farm Size (Acres)', style: AppTextStyles.labelLG),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _farmSizeCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(hintText: 'e.g. 5.0'),
                  validator: (v) => v!.isEmpty ? 'Farm size is required' : null,
                ),
              ],

              // Supplier Fields
              if (!isFarmer) ...[
                Text('Store / Business Name', style: AppTextStyles.labelLG),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _businessNameCtrl,
                  decoration: const InputDecoration(hintText: 'e.g. Patel Krushi Kendra'),
                  validator: (v) => v!.isEmpty ? 'Business name is required' : null,
                ),
                const SizedBox(height: 24),

                Text('District', style: AppTextStyles.labelLG),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _districtCtrl,
                  decoration: const InputDecoration(hintText: 'e.g. Dhule'),
                  validator: (v) => v!.isEmpty ? 'District is required' : null,
                ),
                const SizedBox(height: 24),

                Text('Complete Shop Address', style: AppTextStyles.labelLG),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _addressCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: 'e.g. Shop No 4, Main Market, Shirpur'),
                  validator: (v) => v!.isEmpty ? 'Address is required' : null,
                ),
                const SizedBox(height: 24),

                Text('Google Maps Link (Recommended)', style: AppTextStyles.labelLG),
                const SizedBox(height: 4),
                Text('Help farmers navigate directly to your shop.', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _mapLinkCtrl,
                  decoration: const InputDecoration(hintText: 'e.g. https://maps.app.goo.gl/...'),
                ),
              ],

              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: auth.isLoading ? null : _submit,
                child: auth.isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Complete Setup ✨'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
