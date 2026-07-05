import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../data/services/api_service.dart';
import '../../data/providers/auth_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/responsive.dart';

/// Unified signup screen — adapts form based on [role]
class SignupScreen extends ConsumerStatefulWidget {
  final String role;
  const SignupScreen({super.key, required this.role});
  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _bizCtrl     = TextEditingController();
  final _gstinCtrl   = TextEditingController();
  final _cityCtrl    = TextEditingController();
  final _licenseCtrl = TextEditingController();
  final _apmcCtrl    = TextEditingController();
  final _villageCtrl = TextEditingController();
  final _landCtrl    = TextEditingController();

  String? _selectedDistrict;
  Set<String> _selectedCrops = {};
  Set<String> _selectedCategories = {};
  Set<String> _selectedCommodities = {};
  bool _isLoading = false;
  String? _error;

  Color get _accent   => AppColors.accentFor(widget.role);
  Color get _tint     => AppColors.tintFor(widget.role);
  LinearGradient get _gradient => AppColors.gradientFor(widget.role);

  String get _roleLabel {
    switch (widget.role) {
      case 'SUPPLIER': return 'Supplier';
      case 'DEALER':   return 'Dealer';
      default:         return 'Farmer';
    }
  }

  String get _emoji {
    switch (widget.role) {
      case 'SUPPLIER': return '🏪';
      case 'DEALER':   return '🤝';
      default:         return '🌾';
    }
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _phoneCtrl, _emailCtrl, _passCtrl, _bizCtrl, _gstinCtrl, _cityCtrl, _licenseCtrl, _apmcCtrl, _villageCtrl, _landCtrl]) c.dispose();
    super.dispose();
  }

  bool _validateGstin(String v) => RegExp(r'^\d{2}[A-Z]{5}\d{4}[A-Z]{1}[A-Z\d]{1}[Z]{1}[A-Z\d]{1}$').hasMatch(v);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final phoneString = '+91${_phoneCtrl.text.trim()}';
      
      switch (widget.role) {
        case 'FARMER':
          ApiService.instance.pendingSignupData = {
            'name': _nameCtrl.text.trim(),
            'village': _villageCtrl.text.trim(),
            'district': _selectedDistrict,
            'landSize': double.tryParse(_landCtrl.text),
            'primaryCrops': _selectedCrops.toList(),
          };
          break;
        case 'SUPPLIER':
          ApiService.instance.pendingSignupData = {
            'businessName': _bizCtrl.text.trim(),
            'ownerName': _nameCtrl.text.trim(),
            'email': _emailCtrl.text.trim(),
            'gstin': _gstinCtrl.text.trim().toUpperCase(),
            'city': _cityCtrl.text.trim(),
            'district': _selectedDistrict,
            'categories': _selectedCategories.toList(),
          };
          break;
        case 'DEALER':
          ApiService.instance.pendingSignupData = {
            'businessName': _bizCtrl.text.trim(),
            'ownerName': _nameCtrl.text.trim(),
            'email': _emailCtrl.text.trim(),
            'mandiLicense': _licenseCtrl.text.trim(),
            'apmcYard': _apmcCtrl.text.trim(),
            'commodities': _selectedCommodities.toList(),
          };
          break;
      }
      
      // Send OTP to start the flow
      await ref.read(authProvider.notifier).sendOTP(phone: phoneString, role: widget.role);
      
      if (mounted) {
        context.push('/auth/otp?phone=${Uri.encodeComponent(phoneString)}&role=${widget.role}&language=en');
      }
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 20, 24, 28),
              decoration: BoxDecoration(gradient: _gradient),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(width: 38, height: 38, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20)),
                  ),
                  const SizedBox(height: 20),
                  Text(_emoji, style: const TextStyle(fontSize: 40)),
                  const SizedBox(height: 8),
                  Text('Create Account', style: GoogleFonts.spaceGrotesk(fontSize: r.sp(26), fontWeight: FontWeight.w700, color: Colors.white)),
                  Text('Register as $_roleLabel', style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withValues(alpha: 0.8))),
                ],
              ),
            ),

            // Form card
            Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppColors.deepShadow,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.role != 'FARMER') ...[
                        _buildField('Business Name *', _bizCtrl, 'Agro Traders Pvt Ltd', Icons.business_outlined),
                        const SizedBox(height: 14),
                      ],
                      _buildField(widget.role == 'FARMER' ? 'Full Name *' : 'Owner Name *', _nameCtrl, 'Your name', Icons.person_outline_rounded),
                      const SizedBox(height: 14),
                      _buildPhoneField(),
                      if (widget.role != 'FARMER') ...[
                        const SizedBox(height: 14),
                        _buildField('Email *', _emailCtrl, 'you@example.com', Icons.email_outlined, type: TextInputType.emailAddress),
                      ],
                      if (widget.role == 'SUPPLIER') ...[
                        const SizedBox(height: 14),
                        _buildField('GSTIN *', _gstinCtrl, '27AABCU9603R1ZX', Icons.receipt_long_outlined,
                          formatters: [UpperCaseFormatter()],
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Enter GSTIN';
                            if (!_validateGstin(v.toUpperCase())) return 'Invalid GSTIN format';
                            return null;
                          }),
                        const SizedBox(height: 14),
                        _buildField('City *', _cityCtrl, 'Nashik', Icons.location_city_outlined),
                      ],
                      if (widget.role == 'DEALER') ...[
                        const SizedBox(height: 14),
                        _buildField('Mandi License No. *', _licenseCtrl, 'MH-NAS-2023-001', Icons.badge_outlined),
                        const SizedBox(height: 14),
                        _buildField('APMC Yard / Location *', _apmcCtrl, 'Nashik APMC', Icons.place_outlined),
                      ],
                      if (widget.role == 'FARMER') ...[
                        const SizedBox(height: 14),
                        _buildField('Village / Taluka *', _villageCtrl, 'Chandwad, Nashik', Icons.villa_outlined),
                        const SizedBox(height: 14),
                        _buildField('Land Size (acres)', _landCtrl, '5.5', Icons.landscape_outlined, type: TextInputType.number,
                          formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]),
                      ],

                      // District dropdown
                      const SizedBox(height: 14),
                      _Label('District${widget.role != 'FARMER' ? '' : ' *'}'),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _selectedDistrict,
                        hint: Text('Select district', style: GoogleFonts.inter(color: AppColors.placeholder)),
                        items: AppConstants.maharashtraDistricts.map((d) => DropdownMenuItem(value: d, child: Text(d, style: GoogleFonts.inter(fontSize: 14)))).toList(),
                        onChanged: (v) => setState(() => _selectedDistrict = v),
                        validator: widget.role == 'FARMER' ? (v) => v == null ? 'Select district' : null : null,
                        decoration: InputDecoration(prefixIcon: Icon(Icons.map_outlined, color: _accent, size: 20)),
                      ),

                      // Chips for role-specific multi-select
                      if (widget.role == 'FARMER') ..._buildCropChips(),
                      if (widget.role == 'SUPPLIER') ..._buildCategoryChips(),
                      if (widget.role == 'DEALER') ..._buildCommodityChips(),

                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.dangerTint, borderRadius: BorderRadius.circular(10)),
                          child: Row(children: [
                            const Icon(Icons.error_outline, color: AppColors.danger, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_error!, style: GoogleFonts.inter(fontSize: 13, color: AppColors.danger))),
                          ]),
                        ),
                      ],

                      const SizedBox(height: 24),
                      AppButton(label: widget.role == 'FARMER' ? 'Send OTP & Register' : 'Create Account', onTap: _submit, isLoading: _isLoading, color: _accent, icon: Icons.check_circle_outline_rounded),
                      const SizedBox(height: 16),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('Already have an account? ', style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted)),
                        GestureDetector(
                          onTap: () => context.go('/auth/login?role=${widget.role}'),
                          child: Text('Log In', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _accent)),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, String hint, IconData icon, {
    TextInputType type = TextInputType.text,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Label(label),
      const SizedBox(height: 6),
      TextFormField(
        controller: ctrl,
        keyboardType: type,
        inputFormatters: formatters,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: _accent, size: 20),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _accent, width: 2)),
        ),
        validator: validator ?? (v) => (v == null || v.trim().isEmpty) ? 'This field is required' : null,
      ),
    ],
  );

  Widget _buildPhoneField() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Label('Phone *'),
      const SizedBox(height: 6),
      TextFormField(
        controller: _phoneCtrl,
        keyboardType: TextInputType.phone,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
        decoration: InputDecoration(
          hintText: '9876543210',
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(color: _tint, borderRadius: BorderRadius.circular(8)),
            child: Text('+91', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, color: _accent, fontSize: 13)),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _accent, width: 2)),
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Enter phone number';
          if (v.length != 10) return 'Enter a valid 10-digit number';
          return null;
        },
      ),
    ],
  );

  List<Widget> _buildCropChips() => [
    const SizedBox(height: 20),
    _Label('Primary Crops (select all that apply)'),
    const SizedBox(height: 10),
    Wrap(
      spacing: 8, runSpacing: 8,
      children: AppConstants.popularCrops.map((c) {
        final name = c['name']!;
        final sel  = _selectedCrops.contains(name);
        return GestureDetector(
          onTap: () => setState(() => sel ? _selectedCrops.remove(name) : _selectedCrops.add(name)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: sel ? _accent : AppColors.surface,
              border: Border.all(color: sel ? _accent : AppColors.border),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('${c['emoji']} $name', style: GoogleFonts.inter(fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: sel ? Colors.white : AppColors.ink)),
          ),
        );
      }).toList(),
    ),
  ];

  List<Widget> _buildCategoryChips() => [
    const SizedBox(height: 20),
    _Label('Categories Sold'),
    const SizedBox(height: 10),
    Wrap(
      spacing: 8, runSpacing: 8,
      children: AppConstants.categories.map((c) {
        final key = c['key']!; final label = c['label']!; final emoji = c['icon']!;
        final sel = _selectedCategories.contains(key);
        return GestureDetector(
          onTap: () => setState(() => sel ? _selectedCategories.remove(key) : _selectedCategories.add(key)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: sel ? _accent : AppColors.surface, border: Border.all(color: sel ? _accent : AppColors.border), borderRadius: BorderRadius.circular(20)),
            child: Text('$emoji $label', style: GoogleFonts.inter(fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: sel ? Colors.white : AppColors.ink)),
          ),
        );
      }).toList(),
    ),
  ];

  List<Widget> _buildCommodityChips() {
    const commodities = [
      {'name': 'Onion', 'emoji': '🧅'}, {'name': 'Tomato', 'emoji': '🍅'}, {'name': 'Wheat', 'emoji': '🌾'},
      {'name': 'Soybean', 'emoji': '🫘'}, {'name': 'Cotton', 'emoji': '🌿'}, {'name': 'Grapes', 'emoji': '🍇'},
      {'name': 'Sugarcane', 'emoji': '🍬'}, {'name': 'Maize', 'emoji': '🌽'}, {'name': 'Rice', 'emoji': '🍚'},
    ];
    return [
      const SizedBox(height: 20),
      _Label('Commodities Traded'),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8, runSpacing: 8,
        children: commodities.map((c) {
          final name = c['name']!; final emoji = c['emoji']!;
          final sel = _selectedCommodities.contains(name);
          return GestureDetector(
            onTap: () => setState(() => sel ? _selectedCommodities.remove(name) : _selectedCommodities.add(name)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: sel ? _accent : AppColors.surface, border: Border.all(color: sel ? _accent : AppColors.border), borderRadius: BorderRadius.circular(20)),
              child: Text('$emoji $name', style: GoogleFonts.inter(fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: sel ? Colors.white : AppColors.ink)),
            ),
          );
        }).toList(),
      ),
    ];
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.muted));
}

class UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

