import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/app_providers.dart';
import '../../../data/services/api_service.dart';
import '../../core/utils/responsive.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});
  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String _paymentMethod = 'UPI';
  final _upiCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  bool _isProcessing = false;
  String? _error;

  final _methods = ['UPI', 'Cash on Delivery'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefillAddress());
  }

  void _prefillAddress() {
    final user = ref.read(authProvider).user;
    final farmer = user?.farmer as Map?;
    if (farmer == null) return;
    final parts = [
      farmer['village'],
      farmer['taluka'],
      farmer['district'],
      farmer['pincode'],
    ].where((p) => p != null && p.toString().trim().isNotEmpty).join(', ');
    if (parts.isNotEmpty && _addrCtrl.text.isEmpty) {
      _addrCtrl.text = parts;
    }
  }

  @override
  void dispose() { _upiCtrl.dispose(); _addrCtrl.dispose(); super.dispose(); }

  double _getTotal(Map cart) {
    final items = (cart['items'] as List?) ?? [];
    double total = 0;
    for (final item in items) {
      final price = (item['product']?['price'] as num?) ?? 0;
      final qty   = (item['quantity'] as num?) ?? 0;
      total += price * qty;
    }
    return total + (total >= 500 ? 0 : 50);
  }

  Future<void> _pay() async {
    final r = context.r;
    if (_addrCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Enter delivery address');
      return;
    }
    setState(() { _isProcessing = true; _error = null; });
    try {
      await ref.read(cartProvider.notifier).syncWithServer();
      final cart = ref.read(cartProvider).valueOrNull;
      final items = (cart?['items'] as List?) ?? [];
      if (items.isEmpty) {
        setState(() {
          _isProcessing = false;
          _error = 'Your cart is empty. Add products before checkout.';
        });
        return;
      }

      final isCod = _paymentMethod == 'Cash on Delivery';
      final order = await ApiService.instance.createOrder(
        deliveryAddress: _addrCtrl.text.trim(),
        paymentMethod: isCod ? 'cod' : 'upi',
      );
      final orderId = (order['id'] ?? order['orderId'])?.toString();
      if (orderId == null || orderId.isEmpty) {
        throw Exception('Order was not created. Please try again.');
      }

      if (!isCod) {
        final utr = _upiCtrl.text.trim();
        if (utr.length < 6) {
          setState(() { _isProcessing = false; _error = 'Enter UTR/reference after UPI payment'; });
          return;
        }
        await ApiService.instance.verifyUpiPayment(orderId: orderId, utrNumber: utr);
      }

      ref.read(cartProvider.notifier).clearLocal();
      HapticFeedback.mediumImpact();
      if (mounted) {
        context.go('/farmer/orders');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Order placed successfully!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.rs(10))),
        ));
      }
    } catch (e) {
      setState(() { _isProcessing = false; _error = extractUserFacingError(e); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final cartAsync = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Payment', style: GoogleFonts.spaceGrotesk(fontSize: r.sp(18), fontWeight: FontWeight.w700)),
        leading: GestureDetector(onTap: () => context.pop(), child: const Icon(Icons.arrow_back_rounded)),
      ),
      body: cartAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.farmerAccent)),
        error: (e, _) => Center(child: Text('Error loading cart', style: GoogleFonts.inter(color: AppColors.danger))),
        data: (cart) {
          final total = _getTotal(cart);
          final items = (cart['items'] as List?) ?? [];

          return SingleChildScrollView(
            padding: EdgeInsets.all(r.rs(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Order Summary ────────────────────────────
                Container(
                  padding: EdgeInsets.all(r.rs(20)),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(r.rs(20)), border: Border.all(color: AppColors.border), boxShadow: AppColors.softShadow),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order Summary', style: GoogleFonts.spaceGrotesk(fontSize: r.sp(15), fontWeight: FontWeight.w700, color: AppColors.ink)),
                      SizedBox(height: r.rh(16)),
                      ...items.take(3).map((item) {
                        final name  = item['product']?['name'] ?? 'Product';
                        final price = (item['product']?['price'] as num?) ?? 0;
                        final qty   = (item['quantity'] as num?) ?? 0;
                        return Padding(
                          padding: EdgeInsets.only(bottom: r.rh(10)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text('$name × $qty', style: GoogleFonts.inter(fontSize: r.sp(13), color: AppColors.ink), overflow: TextOverflow.ellipsis)),
                              Text(formatRupee(price * qty), style: GoogleFonts.spaceGrotesk(fontSize: r.sp(13), fontWeight: FontWeight.w600, color: AppColors.ink)),
                            ],
                          ),
                        );
                      }),
                      if (items.length > 3) Text('+ ${items.length - 3} more items', style: GoogleFonts.inter(fontSize: r.sp(12), color: AppColors.muted)),
                      Divider(height: r.rh(20), color: AppColors.border),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Amount', style: GoogleFonts.spaceGrotesk(fontSize: r.sp(16), fontWeight: FontWeight.w700, color: AppColors.ink)),
                          Text(formatRupee(total), style: GoogleFonts.spaceGrotesk(fontSize: r.sp(22), fontWeight: FontWeight.w800, color: AppColors.farmerAccent)),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: r.rh(20)),

                // ── Delivery Address ─────────────────────────
                Text('Delivery Address', style: GoogleFonts.spaceGrotesk(fontSize: r.sp(15), fontWeight: FontWeight.w700, color: AppColors.ink)),
                SizedBox(height: r.rh(10)),
                TextFormField(
                  controller: _addrCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Village, Taluka, District, PIN',
                    prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.farmerAccent),
                    errorText: _error != null && _addrCtrl.text.isEmpty ? 'Enter address' : null,
                  ),
                ),

                SizedBox(height: r.rh(20)),

                // ── Payment Method ───────────────────────────
                Text('Payment Method', style: GoogleFonts.spaceGrotesk(fontSize: r.sp(15), fontWeight: FontWeight.w700, color: AppColors.ink)),
                SizedBox(height: r.rh(12)),
                Container(
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(r.rs(16)), border: Border.all(color: AppColors.border), boxShadow: AppColors.softShadow),
                  child: Column(
                    children: List.generate(_methods.length, (i) {
                      final m = _methods[i];
                      final icons = [Icons.account_balance_wallet_outlined, Icons.money_outlined];
                      final emojis = ['📱', '💵'];
                      return Column(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _paymentMethod = m),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: r.rs(16), vertical: r.rh(14)),
                              child: Row(
                                children: [
                                  Container(
                                    width: r.rs(40), height: 40,
                                    decoration: BoxDecoration(
                                      color: _paymentMethod == m ? AppColors.farmerTint : AppColors.background,
                                      borderRadius: BorderRadius.circular(r.rs(10)),
                                    ),
                                    child: Center(child: Text(emojis[i], style: TextStyle(fontSize: r.sp(20)))),
                                  ),
                                  SizedBox(width: r.rs(12)),
                                  Expanded(child: Text(m, style: GoogleFonts.inter(fontSize: r.sp(14), fontWeight: FontWeight.w500, color: AppColors.ink))),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: r.rs(22), height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _paymentMethod == m ? AppColors.farmerAccent : Colors.transparent,
                                      border: Border.all(
                                        color: _paymentMethod == m ? AppColors.farmerAccent : AppColors.border,
                                        width: r.rs(2),
                                      ),
                                    ),
                                    child: _paymentMethod == m
                                        ? Icon(Icons.check, color: Colors.white, size: r.sp(14))
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (i < _methods.length - 1) Divider(height: r.rh(1), color: AppColors.border),
                        ],
                      );
                    }),
                  ),
                ),

                // UPI ID field
                if (_paymentMethod == 'UPI') ...[
                  SizedBox(height: r.rh(16)),
                  TextFormField(
                    controller: _upiCtrl,
                    decoration: const InputDecoration(
                      hintText: 'UTR / transaction reference',
                      prefixIcon: Icon(Icons.receipt_long_outlined, color: AppColors.farmerAccent),
                      labelText: 'UTR Number (after UPI payment)',
                    ),
                  ),
                ],

                // Error
                if (_error != null) ...[
                  SizedBox(height: r.rh(16)),
                  Container(
                    padding: EdgeInsets.all(r.rs(12)),
                    decoration: BoxDecoration(color: AppColors.dangerTint, borderRadius: BorderRadius.circular(r.rs(12))),
                    child: Row(children: [
                      Icon(Icons.error_outline, color: AppColors.danger, size: r.sp(16)),
                      SizedBox(width: r.rs(8)),
                      Expanded(child: Text(_error!, style: GoogleFonts.inter(fontSize: r.sp(13), color: AppColors.danger))),
                    ]),
                  ),
                ],

                SizedBox(height: r.rh(32)),
                AppButton(
                  label: 'Confirm & Pay ${formatRupee(total)}',
                  onTap: _pay,
                  isLoading: _isProcessing,
                  color: AppColors.farmerAccent,
                  icon: Icons.lock_outlined,
                ),
                SizedBox(height: r.rh(12)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.security, size: r.sp(14), color: AppColors.muted),
                    SizedBox(width: r.rs(6)),
                    Text('Secure payment — 256-bit SSL', style: GoogleFonts.inter(fontSize: r.sp(12), color: AppColors.muted)),
                  ],
                ),
                SizedBox(height: r.rh(80)),
              ],
            ),
          );
        },
      ),
    );
  }
}

