import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
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
  final _stateCtrl = TextEditingController();
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
    _stateCtrl.dispose();
    _farmSizeCtrl.dispose();
    _businessNameCtrl.dispose();
    _addressCtrl.dispose();
    _mapLinkCtrl.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied.')));
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied.')));
      return;
    }

    setState(() => _isLocating = true);

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _villageCtrl.text = place.subLocality ?? place.locality ?? '';
          _districtCtrl.text = place.subAdministrativeArea ?? '';
          _stateCtrl.text = place.administrativeArea ?? '';
          if (_addressCtrl.text.isEmpty) {
            _addressCtrl.text = '${place.name}, ${place.street}, ${place.locality}';
          }
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching location: $e')));
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  bool _isLocating = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authProvider).user;
    if (user == null) return;

    final isFarmer = user.isFarmer;
    final isDealer = user.isDealer;
    
    // We append the map link directly to the address text to avoid Prisma migration for now
    final supplierAddress = '${_addressCtrl.text.trim()}${_mapLinkCtrl.text.isNotEmpty ? ' | MAP: ${_mapLinkCtrl.text.trim()}' : ''}';

    final data = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      if (isFarmer) 'village': _villageCtrl.text.trim(),
      if (isFarmer) 'district': _districtCtrl.text.trim(),
      if (isFarmer) 'state': _stateCtrl.text.trim(),
      if (isFarmer) 'farmSizeAcres': _farmSizeCtrl.text.trim().isNotEmpty ? double.tryParse(_farmSizeCtrl.text.trim()) : 0,
      
      if (!isFarmer) 'businessName': _businessNameCtrl.text.trim(),
      if (!isFarmer) 'address': supplierAddress,
      if (!isFarmer) 'district': _districtCtrl.text.trim(),
      if (!isFarmer) 'state': _stateCtrl.text.trim(),
      
      'role': user.role,
    };

    try {
      await ref.read(authProvider.notifier).completeOnboarding(data);
      if (mounted) {
        if (user.isFarmer) {
          context.go('/farmer');
        } else {
          context.go('/auth/doc-upload');
        }
      }

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
                  : (user.isDealer ? 'Please provide your agency details to start buying crops.' : 'Please provide your shop details so farmers can find you.'),
                style: AppTextStyles.bodyMD.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              
              // New Location Fetch Button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.primaryBorder.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    const Text('📍 High-Accuracy Location', style: AppTextStyles.headingSM),
                    const SizedBox(height: 4),
                    const Text('Auto-fill your address using GPS', style: AppTextStyles.bodyXS),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLocating ? null : _getCurrentLocation,
                        icon: _isLocating 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.my_location, size: 18),
                        label: Text(_isLocating ? 'Locating...' : 'Use Current Location'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Card 1: Personal Details
              _SetupCard(
                title: '👤 Personal Identity',
                children: [
                  const Text('Your Full Name', style: AppTextStyles.labelLG),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(hintText: 'e.g. Ramesh Patel'),
                    validator: (v) => v!.isEmpty ? 'Name is required' : null,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Card 2: Farm/Business Details
              _SetupCard(
                title: isFarmer ? '🌾 Farm Details' : (user.isDealer ? '🤝 Agency Details' : '🏪 Shop Details'),
                children: [
                  if (isFarmer) ...[
                    const Text('Village / Town', style: AppTextStyles.labelLG),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _villageCtrl,
                      decoration: const InputDecoration(hintText: 'e.g. Shirpur'),
                      validator: (v) => v!.isEmpty ? 'Village is required' : null,
                    ),
                    const SizedBox(height: 24),

                    const Text('District', style: AppTextStyles.labelLG),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _districtCtrl,
                      decoration: const InputDecoration(hintText: 'e.g. Dhule'),
                      validator: (v) => v!.isEmpty ? 'District is required' : null,
                    ),
                    const SizedBox(height: 24),

                    const Text('State', style: AppTextStyles.labelLG),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _stateCtrl,
                      decoration: const InputDecoration(hintText: 'e.g. Maharashtra'),
                      validator: (v) => v!.isEmpty ? 'State is required' : null,
                    ),
                    const SizedBox(height: 24),

                    const Text('Farm Size (Acres)', style: AppTextStyles.labelLG),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _farmSizeCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(hintText: 'e.g. 5.0'),
                      validator: (v) => v!.isEmpty ? 'Farm size is required' : null,
                    ),
                  ],

                  if (!isFarmer) ...[
                    Text(user.isDealer ? 'Agency / Business Name' : 'Store / Business Name', style: AppTextStyles.labelLG),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _businessNameCtrl,
                      decoration: InputDecoration(hintText: user.isDealer ? 'e.g. Gaikwad Trading Co.' : 'e.g. Patel Krushi Kendra'),
                      validator: (v) => v!.isEmpty ? 'Business name is required' : null,
                    ),
                    const SizedBox(height: 24),

                    const Text('District', style: AppTextStyles.labelLG),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _districtCtrl,
                      decoration: const InputDecoration(hintText: 'e.g. Dhule'),
                      validator: (v) => v!.isEmpty ? 'District is required' : null,
                    ),
                    const SizedBox(height: 24),

                    const Text('State', style: AppTextStyles.labelLG),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _stateCtrl,
                      decoration: const InputDecoration(hintText: 'e.g. Maharashtra'),
                      validator: (v) => v!.isEmpty ? 'State is required' : null,
                    ),
                    const SizedBox(height: 24),

                    Text(user.isDealer ? 'Agency Address' : 'Complete Shop Address', style: AppTextStyles.labelLG),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _addressCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(hintText: user.isDealer ? 'e.g. Plot No 12, APMC Yard, Jalgaon' : 'e.g. Shop No 4, Main Market, Shirpur'),
                      validator: (v) => v!.isEmpty ? 'Address is required' : null,
                    ),
                    const SizedBox(height: 24),

                    const Text('Google Maps Link (Recommended)', style: AppTextStyles.labelLG),
                    const SizedBox(height: 4),
                    const Text('Help farmers navigate directly to your shop.', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _mapLinkCtrl,
                      decoration: const InputDecoration(hintText: 'e.g. https://maps.app.goo.gl/...'),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: auth.isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 8,
                  shadowColor: AppColors.primary.withValues(alpha: 0.3),
                ),
                child: auth.isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Text('Complete Setup ✨', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetupCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SetupCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppColors.softShadow,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.headingLG.copyWith(color: AppColors.primary)),
          const Divider(height: 32),
          ...children,
        ],
      ),
    );
  }
}
