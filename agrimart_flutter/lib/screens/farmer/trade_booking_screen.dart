import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/api_service.dart';
import 'package:intl/intl.dart';

class TradeBookingScreen extends ConsumerStatefulWidget {
  final String cropName;
  final String district;
  final String dealerId;

  const TradeBookingScreen({
    super.key,
    required this.cropName,
    required this.district,
    required this.dealerId,
  });

  @override
  ConsumerState<TradeBookingScreen> createState() => _TradeBookingScreenState();
}

class _TradeBookingScreenState extends ConsumerState<TradeBookingScreen> {
  final _qtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime? _selectedDate;
  bool _loading = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 14)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: AppColors.primary,
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submitBooking() async {
    if (_qtyCtrl.text.isEmpty || _priceCtrl.text.isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields and select a date.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await ApiService.instance.bookTradeSlot({
        'dealerId': widget.dealerId,
        'cropName': widget.cropName,
        'approxQuintals': double.parse(_qtyCtrl.text.trim()),
        'pricePerQuintal': double.parse(_priceCtrl.text.trim()),
        'slotDate': _selectedDate!.toIso8601String(),
        'notes': _notesCtrl.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Booking Successful! The dealer will confirm soon.'), backgroundColor: AppColors.success),
        );
        context.pop();
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Book Delivery Slot'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                boxShadow: AppColors.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Trading Details', style: AppTextStyles.headingMD),
                  const Divider(height: 24),
                  _DetailRow(label: 'Crop', value: widget.cropName),
                  const SizedBox(height: 12),
                  _DetailRow(label: 'Location', value: widget.district),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('Booking Information', style: AppTextStyles.headingMD),
            const SizedBox(height: 16),
            
            Text('Approx. Quantity (Quintals) *', style: AppTextStyles.labelLG),
            const SizedBox(height: 8),
            TextField(
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'e.g. 50'),
            ),
            const SizedBox(height: 24),

            Text('Expected Price per Quintal (₹) *', style: AppTextStyles.labelLG),
            const SizedBox(height: 8),
            TextField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'e.g. 4500'),
            ),
            const SizedBox(height: 24),

            Text('Select Delivery Date *', style: AppTextStyles.labelLG),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDate == null ? 'Tap to select date' : DateFormat('EEE, d MMM yyyy').format(_selectedDate!),
                      style: AppTextStyles.bodyLG.copyWith(
                        color: _selectedDate == null ? AppColors.textTertiary : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text('Additional Notes (Optional)', style: AppTextStyles.labelLG),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Any special requirements or notes for the dealer...'),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _loading ? null : _submitBooking,
                child: _loading 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Text('Confirm Booking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  const _DetailRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodySM.copyWith(color: AppColors.textSecondary)),
        Text(value, style: AppTextStyles.headingSM),
      ],
    );
  }
}
