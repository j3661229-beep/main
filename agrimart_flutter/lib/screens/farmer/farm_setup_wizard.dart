import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/location_helper.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/agri_ui.dart';
import '../../core/utils/farmer_prefetch.dart';
import '../../data/providers/auth_provider.dart';

class FarmSetupWizard extends ConsumerStatefulWidget {
  const FarmSetupWizard({super.key});

  @override
  ConsumerState<FarmSetupWizard> createState() => _FarmSetupWizardState();
}

class _FarmSetupWizardState extends ConsumerState<FarmSetupWizard> {
  final _pageCtrl = PageController();
  int _step = 0;
  bool _saving = false;
  bool _locating = false;
  bool _locationAutoFilled = false;
  String? _locationError;

  final _nameCtrl = TextEditingController();
  final _villageCtrl = TextEditingController();
  final _talukaCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _acresCtrl = TextEditingController();

  String _district = 'Nashik';
  String _state = 'Maharashtra';
  double? _latitude;
  double? _longitude;
  final Set<String> _selectedCrops = {};
  String _season = 'Kharif';
  String? _soilType;
  String? _waterSource;
  String? _irrigationType;

  static const _soilTypes = [
    'Black cotton',
    'Red laterite',
    'Alluvial',
    'Sandy',
    'Loamy',
    'Clay',
  ];

  static const _waterSources = [
    'Rain-fed',
    'Well / Borewell',
    'Canal',
    'River / Lake',
    'Drip tank',
  ];

  static const _irrigationTypes = [
    'Flood',
    'Drip',
    'Sprinkler',
    'Furrow',
    'Manual',
  ];

  static const _seasons = ['Kharif', 'Rabi', 'Zaid'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (ref.read(authProvider).farmSetupComplete) {
        if (mounted) context.go('/farmer');
        return;
      }
      _prefill();
      _season = currentFarmingSeason();
      await _autoFetchLocation(silent: true);
    });
  }

  void _prefill() {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    _nameCtrl.text = user.name == 'AgriMart User' ? '' : user.name;
    final f = user.farmer;
    if (f == null) {
      setState(() {});
      return;
    }
    _villageCtrl.text = f['village']?.toString() ?? '';
    _talukaCtrl.text = f['taluka']?.toString() ?? '';
    _pincodeCtrl.text = f['pincode']?.toString() ?? '';
    _district = f['district']?.toString() ?? 'Nashik';
    _state = f['state']?.toString() ?? 'Maharashtra';
    _latitude = (f['latitude'] as num?)?.toDouble();
    _longitude = (f['longitude'] as num?)?.toDouble();
    final acres = f['farmSizeAcres'];
    if (acres != null && (acres is num ? acres : double.tryParse('$acres') ?? 0) > 0) {
      _acresCtrl.text = acres.toString();
    }
    final crops = f['currentCrops'];
    if (crops is List) _selectedCrops.addAll(crops.map((e) => e.toString()));
    _soilType = f['soilType']?.toString();
    _waterSource = f['waterSource']?.toString().split('(').first.trim();
    if (_latitude != null && _longitude != null && _villageCtrl.text.isNotEmpty) {
      _locationAutoFilled = true;
    }
    setState(() {});
  }

  void _applyLocationResult(LocationResult loc, {bool applySmartDefaults = true}) {
    _latitude = loc.latitude;
    _longitude = loc.longitude;
    if (loc.village.isNotEmpty) _villageCtrl.text = loc.village;
    if (loc.taluka.isNotEmpty) _talukaCtrl.text = loc.taluka;
    if (loc.pincode.isNotEmpty) _pincodeCtrl.text = loc.pincode;
    if (loc.district.isNotEmpty) _district = loc.district;
    if (loc.state.isNotEmpty) _state = loc.state;
    _locationAutoFilled = true;
    _locationError = null;

    if (applySmartDefaults) {
      _season = currentFarmingSeason();
      if (_selectedCrops.isEmpty) {
        _selectedCrops.addAll(suggestedCropsForSeason(_season));
      }
    }
  }

  Future<void> _autoFetchLocation({bool silent = false}) async {
    if (_locating) return;
    setState(() {
      _locating = true;
      _locationError = null;
    });
    try {
      final loc = await LocationHelper.getCurrent();
      if (loc == null) {
        if (!silent) {
          _snack(_t(
            'Turn on GPS & allow location permission',
            'GPS चालू करें और अनुमति दें',
            'GPS चालू करा आणि परवानगी द्या',
          ));
        }
        setState(() => _locationError = _t(
          'Location not detected — tap below or enter manually',
          'लोकेशन नहीं मिला — नीचे टैप करें',
          'स्थान मिळाले नाही — खाली टॅप करा',
        ));
        return;
      }
      _applyLocationResult(loc);
      if (!silent) {
        _snack(_t('All location details filled ✓', 'सभी जानकारी भर गई ✓', 'सर्व माहिती भरली ✓'));
      }
    } catch (_) {
      if (!silent) {
        _snack(_t('Could not get GPS', 'GPS नहीं मिला', 'GPS मिळाला नाही'));
      }
      setState(() => _locationError = _t(
        'Could not detect location',
        'लोकेशन नहीं मिला',
        'स्थान मिळाले नाही',
      ));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _captureGps() => _autoFetchLocation(silent: false);

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    _villageCtrl.dispose();
    _talukaCtrl.dispose();
    _pincodeCtrl.dispose();
    _acresCtrl.dispose();
    super.dispose();
  }

  String _t(String en, String hi, String mr) {
    final code = ref.read(localeProvider).languageCode;
    if (code == 'hi') return hi;
    if (code == 'mr') return mr;
    return en;
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  bool _validateStep(int step) {
    switch (step) {
      case 0:
        if (_nameCtrl.text.trim().isEmpty) {
          _snack(_t('Enter your name', 'नाम दर्ज करें', 'नाव लिहा'));
          return false;
        }
        if (_villageCtrl.text.trim().isEmpty || _district.isEmpty) {
          _snack(_t('Village and district required', 'गाँव और जिला जरूरी', 'गाव आणि जिल्हा आवश्यक'));
          return false;
        }
        return true;
      case 1:
        if (_latitude == null || _longitude == null) {
          _snack(_t('Tap "Use GPS" to set farm location', 'GPS से लोकेशन सेट करें', 'GPS वरून स्थान सेट करा'));
          return false;
        }
        return true;
      case 2:
        final acres = double.tryParse(_acresCtrl.text.trim());
        if (acres == null || acres <= 0) {
          _snack(_t('Enter valid farm size in acres', 'एकड़ में जमीन का आकार', 'एकरमध्ये शेताचे क्षेत्रफळ'));
          return false;
        }
        return true;
      case 3:
        if (_selectedCrops.isEmpty) {
          _snack(_t('Select at least one crop', 'कम से कम एक फसल चुनें', 'किमान एक पीक निवडा'));
          return false;
        }
        return true;
      case 4:
        if (_soilType == null || _waterSource == null || _irrigationType == null) {
          _snack(_t('Select soil, water & irrigation', 'मिट्टी, पानी व सिंचाई चुनें', 'माती, पाणी व सिंचन निवडा'));
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _next() {
    if (!_validateStep(_step)) return;
    if (_step < 4) {
      setState(() => _step++);
      _pageCtrl.animateToPage(_step, duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    } else {
      _submit();
    }
  }

  void _back() {
    if (_step == 0) return;
    setState(() => _step--);
    _pageCtrl.animateToPage(_step, duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
  }

  Future<void> _submit() async {
    if (!_validateStep(4)) return;
    setState(() => _saving = true);
    try {
      final payload = {
        'name': _nameCtrl.text.trim(),
        'village': _villageCtrl.text.trim(),
        'taluka': _talukaCtrl.text.trim(),
        'district': _district,
        'state': _state,
        'pincode': _pincodeCtrl.text.trim(),
        'latitude': _latitude,
        'longitude': _longitude,
        'farmSizeAcres': double.parse(_acresCtrl.text.trim()),
        'currentCrops': _selectedCrops.toList(),
        'farmingSeason': _season,
        'soilType': _soilType,
        'waterSource': _waterSource,
        'irrigationType': _irrigationType,
        'role': 'FARMER',
      };
      await ref.read(authProvider.notifier).completeOnboarding(payload);
      if (mounted) {
        prefetchFarmerHomeData(ref);
        context.go('/farmer');
      }
    } catch (e) {
      _snack(_t('Save failed — try again', 'सेव नहीं हुआ', 'जतन अयशस्वी'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final titles = [
      _t('Your details', 'आपकी जानकारी', 'तुमची माहिती'),
      _t('Farm GPS', 'खेत का GPS', 'शेताचे GPS'),
      _t('Land size', 'जमीन का आकार', 'जमीन माप'),
      _t('Crops & season', 'फसल और मौसम', 'पिके व हंगाम'),
      _t('Soil & water', 'मिट्टी और पानी', 'माती व पाणी'),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.farmerAccent,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Text(
          _t('Farm Setup', 'खेत सेटअप', 'शेत सेटअप'),
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(r.rh(36)),
          child: Padding(
            padding: EdgeInsets.fromLTRB(r.rs(20), r.rh(0), r.rs(20), r.rh(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_t('Step', 'चरण', 'पायरी')} ${_step + 1}/5 — ${titles[_step]}',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: r.sp(13)),
                ),
                SizedBox(height: r.rh(8)),
                ClipRRect(
                  borderRadius: BorderRadius.circular(r.rs(4)),
                  child: LinearProgressIndicator(
                    value: (_step + 1) / 5,
                    minHeight: r.rh(5),
                    backgroundColor: Colors.white24,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: ResponsiveLayout(
        applyPadding: false,
        child: PageView(
        controller: _pageCtrl,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _stepCard([
            if (_locating)
              Padding(
                padding: EdgeInsets.only(bottom: r.rh(16)),
                child: Row(
                  children: [
                    SizedBox(width: r.rs(20),
                      height: r.rh(20),
                      child: CircularProgressIndicator(strokeWidth: r.rs(2), color: AppColors.farmerAccent),
                    ),
                    SizedBox(width: r.rs(12)),
                    Expanded(
                      child: Text(
                        _t(
                          'Detecting your farm location…',
                          'आपके खेत की लोकेशन मिल रही है…',
                          'तुमच्या शेताचे स्थान शोधत आहे…',
                        ),
                        style: GoogleFonts.inter(fontSize: r.sp(13), color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              )
            else if (_locationAutoFilled)
              _locationStatusCard()
            else if (_locationError != null)
              Padding(
                padding: EdgeInsets.only(bottom: r.rh(16)),
                child: Text(_locationError!, style: GoogleFonts.inter(fontSize: r.sp(13), color: AppColors.warning)),
              ),
            FarmerActionButton(
              label: _locating
                  ? _t('Getting location…', 'लोकेशन मिल रहा…', 'स्थान मिळत आहे…')
                  : _t('Refresh GPS location', 'GPS से भरें', 'GPS वरून भरा'),
              icon: Icons.my_location_rounded,
              onTap: _locating ? null : _captureGps,
              accent: AppColors.farmerAccent,
            ),
            SizedBox(height: r.rh(20)),
            _label(_t('Full name', 'पूरा नाम', 'पूर्ण नाव')),
            _field(_nameCtrl, _t('e.g. Ramesh Patil', 'उदा. रमेश पाटिल', 'उदा. रमेश पाटील')),
            SizedBox(height: r.rh(16)),
            _label(_t('Village / town', 'गाँव', 'गाव')),
            _field(_villageCtrl, _t('e.g. Shirpur', 'उदा. शिरपूर', 'उदा. शिरपूर')),
            SizedBox(height: r.rh(16)),
            _label(_t('Taluka', 'तहसील', 'तालुका')),
            _field(_talukaCtrl, _t('e.g. Shirpur', 'उदा. शिरपूर', 'उदा. शिरपूर')),
            SizedBox(height: r.rh(16)),
            _label(_t('District', 'जिला', 'जिल्हा')),
            DropdownButtonFormField<String>(
              value: AppConstants.maharashtraDistricts.contains(_district) ? _district : 'Nashik',
              decoration: _inputDeco(),
              items: AppConstants.maharashtraDistricts
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (v) => setState(() => _district = v ?? _district),
            ),
            SizedBox(height: r.rh(16)),
            _label(_t('Pincode', 'पिनकोड', 'पिनकोड')),
            _field(_pincodeCtrl, '424001', keyboard: TextInputType.number),
          ]),
          _stepCard([
            Text(
              _t(
                'Your GPS location was captured automatically. Confirm or tap refresh.',
                'GPS लोकेशन अपने आप भर गई। पुष्टि करें या रीफ्रेश करें।',
                'GPS स्थान आपोआप भरले. पुष्टी करा किंवा रिफ्रेश करा.',
              ),
              style: GoogleFonts.inter(color: AppColors.textSecondary, height: 1.4),
            ),
            SizedBox(height: r.rh(16)),
            if (_locationAutoFilled) _locationStatusCard(),
            SizedBox(height: r.rh(12)),
            FarmerActionButton(
              label: _locating
                  ? _t('Getting location…', 'लोकेशन मिल रहा…', 'स्थान मिळत आहे…')
                  : _t('Refresh GPS location', 'GPS रीफ्रेश', 'GPS रिफ्रेश'),
              icon: Icons.my_location_rounded,
              onTap: _locating ? null : _captureGps,
              accent: AppColors.farmerAccent,
            ),
          ]),
          _stepCard([
            _label(_t('Farm size (acres)', 'खेत (एकड़)', 'शेत (एकर)')),
            _field(_acresCtrl, _t('e.g. 2.5', 'उदा. 2.5', 'उदा. 2.5'), keyboard: const TextInputType.numberWithOptions(decimal: true)),
            SizedBox(height: r.rh(12)),
            Text(
              _t('Required for fertilizer doses & insurance calculations.',
                  'खाद व बीमा के लिए जरूरी।', 'खते व विम्यासाठी आवश्यक.'),
              style: GoogleFonts.inter(fontSize: r.sp(13), color: AppColors.textSecondary),
            ),
          ]),
          _stepCard([
            _label(_t('Current crops (select all)', 'फसलें चुनें', 'सध्याची पिके')),
            Wrap(
              spacing: r.rs(8),
              runSpacing: r.rs(8),
              children: AppConstants.popularCrops.map((c) {
                final name = c['name']!;
                final selected = _selectedCrops.contains(name);
                return FilterChip(
                  label: Text('${c['emoji']} $name'),
                  selected: selected,
                  onSelected: (v) => setState(() {
                    if (v) {
                      _selectedCrops.add(name);
                    } else {
                      _selectedCrops.remove(name);
                    }
                  }),
                  selectedColor: AppColors.farmerAccent.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.farmerAccent,
                );
              }).toList(),
            ),
            SizedBox(height: r.rh(20)),
            _label(_t('Farming season', 'फसल का मौसम', 'शेती हंगाम')),
            Wrap(
              spacing: r.rs(8),
              children: _seasons.map((s) {
                return ChoiceChip(
                  label: Text(s),
                  selected: _season == s,
                  onSelected: (_) => setState(() => _season = s),
                  selectedColor: AppColors.farmerAccent.withValues(alpha: 0.2),
                );
              }).toList(),
            ),
          ]),
          _stepCard([
            _label(_t('Soil type', 'मिट्टी का प्रकार', 'मातीचा प्रकार')),
            ..._soilTypes.map((s) => RadioListTile<String>(
                  title: Text(s, style: GoogleFonts.inter(fontSize: r.sp(14))),
                  value: s,
                  groupValue: _soilType,
                  activeColor: AppColors.farmerAccent,
                  onChanged: (v) => setState(() => _soilType = v),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                )),
            Divider(height: r.rh(24)),
            _label(_t('Water source', 'पानी का स्रोत', 'पाण्याचा स्रोत')),
            Wrap(
              spacing: r.rs(8),
              runSpacing: r.rs(8),
              children: _waterSources.map((w) {
                return ChoiceChip(
                  label: Text(w),
                  selected: _waterSource == w,
                  onSelected: (_) => setState(() => _waterSource = w),
                );
              }).toList(),
            ),
            SizedBox(height: r.rh(16)),
            _label(_t('Irrigation type', 'सिंचाई', 'सिंचन पद्धत')),
            Wrap(
              spacing: r.rs(8),
              runSpacing: r.rs(8),
              children: _irrigationTypes.map((i) {
                return ChoiceChip(
                  label: Text(i),
                  selected: _irrigationType == i,
                  onSelected: (_) => setState(() => _irrigationType = i),
                );
              }).toList(),
            ),
          ]),
        ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(r.rs(20), r.rh(8), r.rs(20), r.rh(16)),
          child: Row(
            children: [
              if (_step > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : _back,
                    child: Text(_t('Back', 'पीछे', 'मागे')),
                  ),
                ),
              if (_step > 0) SizedBox(width: r.rs(12)),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _saving ? null : _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.farmerAccent,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: r.rh(16)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.rs(16))),
                  ),
                  child: _saving
                      ? SizedBox(width: r.rs(22), height: r.rh(22), child: CircularProgressIndicator(strokeWidth: r.rs(2), color: Colors.white))
                      : Text(
                          _step == 4
                              ? _t('Finish setup ✓', 'सेटअप पूरा करें', 'सेटअप पूर्ण करा')
                              : _t('Next', 'आगे', 'पुढे'),
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepCard(List<Widget> children) {
    final r = context.r;
    return ListView(
      padding: EdgeInsets.all(r.rs(20)),
      children: [
        Container(
          padding: EdgeInsets.all(r.rs(20)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(r.rs(24)),
            boxShadow: AppColors.softShadow,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      ],
    );
  }

  Widget _label(String text) {
    final r = context.r;
    return Padding(
      padding: EdgeInsets.only(bottom: r.rh(8)),
      child: Text(text, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: r.sp(14))),
    );
  }

  InputDecoration _inputDeco() {
    final r = context.r;
    return InputDecoration(
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(r.rs(14)), borderSide: BorderSide.none),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, {TextInputType? keyboard}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      decoration: _inputDeco().copyWith(hintText: hint),
    );
  }

  Widget _locationStatusCard() {
    final r = context.r;
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: r.rh(16)),
      padding: EdgeInsets.all(r.rs(16)),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(r.rs(16)),
        border: Border.all(color: AppColors.primaryBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📍 ${_t('Auto-filled from GPS', 'GPS से भरा', 'GPS वरून भरले')}',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: r.rh(8)),
          if (_villageCtrl.text.isNotEmpty)
            Text('${_t("Village", "गाँव", "गाव")}: ${_villageCtrl.text}', style: GoogleFonts.inter(fontSize: r.sp(13))),
          if (_talukaCtrl.text.isNotEmpty)
            Text('${_t("Taluka", "तहसील", "तालुका")}: ${_talukaCtrl.text}', style: GoogleFonts.inter(fontSize: r.sp(13))),
          Text('${_t("District", "जिला", "जिल्हा")}: $_district', style: GoogleFonts.inter(fontSize: r.sp(13))),
          if (_pincodeCtrl.text.isNotEmpty)
            Text('${_t("Pincode", "पिनकोड", "पिनकोड")}: ${_pincodeCtrl.text}', style: GoogleFonts.inter(fontSize: r.sp(13))),
          if (_latitude != null && _longitude != null)
            Text(
              'GPS: ${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
              style: GoogleFonts.inter(fontSize: r.sp(12), color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }
}
