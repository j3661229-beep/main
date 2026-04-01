import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/api_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BookTradeSlotScreen extends StatefulWidget {
  final String cropName;
  final String district;

  const BookTradeSlotScreen({super.key, required this.cropName, required this.district});

  @override
  State<BookTradeSlotScreen> createState() => _BookTradeSlotScreenState();
}

class _BookTradeSlotScreenState extends State<BookTradeSlotScreen> {
  final TextEditingController _weightCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  
  List<Map<String, dynamic>> _dealers = [];
  bool _loading = true;
  String? _selectedDealerId;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  double _selectedRate = 0.0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchDealers();
  }

  Future<void> _fetchDealers() async {
    try {
      final rates = await ApiService.instance.getDealerRates(district: widget.district, crop: widget.cropName);
      setState(() {
        _dealers = List<Map<String, dynamic>>.from(rates);
        if (_dealers.isNotEmpty) {
          _selectedDealerId = _dealers[0]['supplierId'];
          _selectedRate = (_dealers[0]['pricePerQuintal'] as num).toDouble();
        }
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary, 
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitBooking() async {
    if (_selectedDealerId == null) return;
    if (_weightCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.enterWeightError)));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final res = await ApiService.instance.bookTradeSlot({
        'supplierId': _selectedDealerId,
        'cropName': widget.cropName,
        'approxQuintals': double.parse(_weightCtrl.text),
        'pricePerQuintal': _selectedRate,
        'slotDate': _selectedDate.toIso8601String(),
        'notes': _notesCtrl.text,
      });

      if (mounted) {
        setState(() => _isSubmitting = false);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            contentPadding: const EdgeInsets.all(32),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(color: AppColors.primarySurface, shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 48),
                ),
                const SizedBox(height: 24),
                Text(l10n.bookingConfirmed, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Text('${l10n.deliverySlotConfirmed} ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}.', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, height: 1.4)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text(l10n.backToDashboard, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )
              ]
            )
          )
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.errorBookingSlot}: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${l10n.sellPrefix} ${widget.cropName}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _dealers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.storefront_outlined, size: 64, color: AppColors.textTertiary),
                      const SizedBox(height: 16),
                      Text(l10n.noDealersFound(widget.cropName, widget.district), style: const TextStyle(color: AppColors.textSecondary, fontSize: 16), textAlign: TextAlign.center),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: FadeInUp(
                    duration: const Duration(milliseconds: 500),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.selectLocalDealer, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.5)),
                        const SizedBox(height: 12),
                        ..._dealers.map((dealer) {
                          final isSelected = dealer['supplierId'] == _selectedDealerId;
                          final rate = (dealer['pricePerQuintal'] as num).toDouble();
                          final sName = dealer['supplier']?['user']?['name'] ?? 'Local Dealer';
                          
                          return GestureDetector(
                            onTap: () => setState(() {
                              _selectedDealerId = dealer['supplierId'];
                              _selectedRate = rate;
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primarySurface : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: isSelected ? 2 : 1),
                                boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))] : [],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48, height: 48,
                                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                                    child: const Icon(Icons.storefront_rounded, color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(sName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary)),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.verified_rounded, color: AppColors.success, size: 14),
                                            const SizedBox(width: 4),
                                            Text('${widget.district} ${l10n.verifiedDistrict}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                                          ],
                                        )
                                      ],
                                    )
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('₹$rate', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.primaryDark)),
                                      Text(l10n.perQuintalShort, style: const TextStyle(fontSize: 10, color: AppColors.textTertiary, fontWeight: FontWeight.bold)),
                                    ],
                                  )
                                ],
                              ),
                            )
                          );
                        }).toList(),
                        const SizedBox(height: 32),
                        Text(l10n.bookingDetails, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.5)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.approxWeightQuintals, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _weightCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'e.g., 50',
                                  filled: true,
                                  fillColor: AppColors.surface,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(l10n.dropOffDate, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => _selectDate(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                      const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(l10n.additionalNotesOptional, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _notesCtrl,
                                decoration: InputDecoration(
                                  hintText: 'Any special instructions...',
                                  filled: true,
                                  fillColor: AppColors.surface,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                              ),
                            ]
                          )
                        ),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: _dealers.isEmpty ? null : Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSubmitting 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                : Text(l10n.confirmBookingSlot, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            )
          )
        )
      )
    );
  }
}
