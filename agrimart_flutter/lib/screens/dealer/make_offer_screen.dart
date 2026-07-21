import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../core/utils/responsive.dart';

class MakeOfferScreen extends ConsumerStatefulWidget {
  final Map listing;
  const MakeOfferScreen({super.key, required this.listing});
  @override
  ConsumerState<MakeOfferScreen> createState() => _MakeOfferScreenState();
}

class _MakeOfferScreenState extends ConsumerState<MakeOfferScreen> {
  late TextEditingController _offerCtrl;
  DateTime? _pickupDate;
  final _formKey = GlobalKey<FormState>();

  late double _askingPrice;
  late double _quantity;

  @override
  void initState() {
    super.initState();
    _askingPrice = ((widget.listing['expectedPrice'] ?? widget.listing['askingPrice']) as num?)?.toDouble() ?? 0;
    _quantity    = ((widget.listing['quantity']) as num?)?.toDouble() ?? 0;
    _offerCtrl   = TextEditingController(text: _askingPrice.toStringAsFixed(0));
  }

  @override
  void dispose() { _offerCtrl.dispose(); super.dispose(); }

  double get _offerPrice => double.tryParse(_offerCtrl.text) ?? _askingPrice;
  double get _total      => _offerPrice * _quantity;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 2)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.dealerAccent)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _pickupDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final l = widget.listing;
    final crop       = l['crop'] ?? 'Crop';
    final farmerName = l['farmerName'] ?? l['farmer']?['name'] ?? 'Farmer';
    final village    = l['village'] ?? l['farmer']?['village'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Make Offer', style: GoogleFonts.spaceGrotesk(fontSize: r.sp(18), fontWeight: FontWeight.w700)),
        leading: GestureDetector(onTap: () => context.pop(), child: const Icon(Icons.arrow_back_rounded)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(r.rs(16)),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Summary card ─────────────────────────────
              Container(
                padding: EdgeInsets.all(r.rs(20)),
                decoration: BoxDecoration(
                  gradient: AppColors.dealerGradient,
                  borderRadius: BorderRadius.circular(r.rs(20)),
                  boxShadow: [BoxShadow(color: AppColors.dealerAccent.withValues(alpha: 0.3), blurRadius: r.rs(16), offset: Offset(0, 8))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Produce Summary', style: GoogleFonts.inter(fontSize: r.sp(12), color: Colors.white.withValues(alpha: 0.8))),
                    SizedBox(height: r.rh(6)),
                    Text(crop, style: GoogleFonts.spaceGrotesk(fontSize: r.sp(26), fontWeight: FontWeight.w800, color: Colors.white)),
                    SizedBox(height: r.rh(12)),
                    Row(children: [
                      _SummaryChip(label: 'Farmer', value: farmerName),
                      SizedBox(width: r.rs(16)),
                      if (village.isNotEmpty) _SummaryChip(label: 'Village', value: village),
                    ]),
                    SizedBox(height: r.rh(10)),
                    Row(children: [
                      _SummaryChip(label: 'Quantity', value: '${_quantity.toInt()} qtl'),
                      SizedBox(width: r.rs(16)),
                      _SummaryChip(label: 'Asking', value: '${formatRupee(_askingPrice)}/qtl'),
                    ]),
                  ],
                ),
              ),

              SizedBox(height: r.rh(20)),

              // ── Offer form ────────────────────────────────
              Container(
                padding: EdgeInsets.all(r.rs(20)),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(r.rs(20)),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppColors.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your Offer', style: GoogleFonts.spaceGrotesk(fontSize: r.sp(16), fontWeight: FontWeight.w700, color: AppColors.ink)),
                    SizedBox(height: r.rh(16)),

                    Text('Offer Price / quintal *', style: GoogleFonts.inter(fontSize: r.sp(13), fontWeight: FontWeight.w500, color: AppColors.muted)),
                    SizedBox(height: r.rh(6)),
                    TextFormField(
                      controller: _offerCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                      style: GoogleFonts.spaceGrotesk(fontSize: r.sp(20), fontWeight: FontWeight.w700, color: AppColors.dealerAccent),
                      decoration: InputDecoration(
                        prefixText: '₹ ',
                        prefixStyle: GoogleFonts.spaceGrotesk(fontSize: r.sp(20), fontWeight: FontWeight.w700, color: AppColors.dealerAccent),
                        suffixText: '/qtl',
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(r.rs(12)), borderSide: BorderSide(color: AppColors.dealerAccent, width: 2)),
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter offer price';
                        if (double.tryParse(v) == null) return 'Invalid price';
                        return null;
                      },
                    ),

                    SizedBox(height: r.rh(16)),

                    Text('Pickup Date *', style: GoogleFonts.inter(fontSize: r.sp(13), fontWeight: FontWeight.w500, color: AppColors.muted)),
                    SizedBox(height: r.rh(6)),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: EdgeInsets.all(r.rs(14)),
                        decoration: BoxDecoration(
                          border: Border.all(color: _pickupDate != null ? AppColors.dealerAccent : AppColors.border, width: _pickupDate != null ? 2 : 1),
                          borderRadius: BorderRadius.circular(r.rs(12)),
                          color: AppColors.surface,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, color: AppColors.dealerAccent, size: r.sp(20)),
                            SizedBox(width: r.rs(10)),
                            Text(
                              _pickupDate != null
                                  ? '${_pickupDate!.day} ${_months[_pickupDate!.month - 1]} ${_pickupDate!.year}'
                                  : 'Select pickup date',
                              style: GoogleFonts.inter(fontSize: r.sp(14), color: _pickupDate != null ? AppColors.ink : AppColors.placeholder),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: r.rh(20)),
                    const Divider(color: AppColors.border),
                    SizedBox(height: r.rh(16)),

                    // Live total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Computed Total', style: GoogleFonts.inter(fontSize: r.sp(12), color: AppColors.muted)),
                            Text('${formatRupee(_offerPrice)}/qtl × ${_quantity.toInt()} qtl', style: GoogleFonts.inter(fontSize: r.sp(12), color: AppColors.muted)),
                          ],
                        ),
                        Text(formatRupee(_total), style: GoogleFonts.spaceGrotesk(fontSize: r.sp(24), fontWeight: FontWeight.w800, color: AppColors.dealerAccent)),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: r.rh(24)),
              AppButton(
                label: 'Send Offer & Pay Advance',
                onTap: () {
                  if (!_formKey.currentState!.validate()) return;
                  if (_pickupDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a pickup date'), backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating));
                    return;
                  }
                  context.push('/dealer/advance-payment', extra: {
                    'listing': widget.listing,
                    'offerPrice': _offerPrice,
                    'pickupDate': _pickupDate!.toIso8601String(),
                    'total': _total,
                  });
                },
                color: AppColors.dealerAccent,
                icon: Icons.send_rounded,
              ),
              SizedBox(height: r.rh(80)),
            ],
          ),
        ),
      ),
    );
  }

  static const _months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
}

class _SummaryChip extends StatelessWidget {
  final String label, value;
  const _SummaryChip({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: GoogleFonts.inter(fontSize: r.sp(11), color: Colors.white.withValues(alpha: 0.7))),
      Text(value, style: GoogleFonts.spaceGrotesk(fontSize: r.sp(14), fontWeight: FontWeight.w600, color: Colors.white)),
    ],
  );
  }
}

