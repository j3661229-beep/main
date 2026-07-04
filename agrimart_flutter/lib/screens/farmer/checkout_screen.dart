// Checkout — COD and UPI (UTR) payment flow
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers/app_providers.dart';
import '../../data/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shimmer.dart';
import '../../core/widgets/app_fallback.dart';
import '../../core/widgets/app_snackbar.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});
  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String _pickupTime = 'Today, 10:00 AM - 12:00 PM';
  bool _placing = false;
  String? _pendingOrderId;
  String _paymentMethod = 'COD';
  final _utrCtrl = TextEditingController();
  Map? _upiDetails;
  String? _error;

  @override
  void dispose() {
    _utrCtrl.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    setState(() { _placing = true; _error = null; });
    try {
      final order = await ApiService.instance.createOrder(
        deliveryAddress: 'In-Store Pickup: $_pickupTime',
        paymentMethod: _paymentMethod == 'COD' ? 'cod' : 'upi',
      );
      _pendingOrderId = order['id'] as String;

      if (_paymentMethod == 'COD') {
        await ApiService.instance.confirmCashOnDelivery(_pendingOrderId!);
        ref.read(cartProvider.notifier).clear();
        if (!mounted) return;
        setState(() => _placing = false);
        AppSnackbar.success(context, 'Order placed with Cash on Delivery');
        context.go('/farmer/orders');
        return;
      }

      // UPI — load supplier UPI details, farmer pays externally then submits UTR
      final details = await ApiService.instance.getOrderUpiDetails(_pendingOrderId!);
      if (!mounted) return;
      setState(() {
        _upiDetails = details;
        _placing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _placing = false; _error = e.toString(); });
    }
  }

  Future<void> _submitUtr() async {
    if (_pendingOrderId == null) return;
    final utr = _utrCtrl.text.trim();
    if (utr.length < 6) {
      setState(() => _error = 'Enter valid UTR/reference number from your UPI app');
      return;
    }
    setState(() { _placing = true; _error = null; });
    try {
      await ApiService.instance.verifyUpiPayment(orderId: _pendingOrderId!, utrNumber: utr);
      ref.read(cartProvider.notifier).clear();
      if (!mounted) return;
      setState(() => _placing = false);
      AppSnackbar.success(context, 'UPI payment verified. Order confirmed!');
      context.go('/farmer/orders');
    } catch (e) {
      if (!mounted) return;
      setState(() { _placing = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: cart.when(
        loading: () => const AppShimmerList(itemCount: 4),
        error: (e, _) => AppErrorState(
          message: e.toString(),
          onRetry: () => ref.read(cartProvider.notifier).load(),
        ),
        data: (data) {
          final items = data['items'] as List? ?? [];
          final total = items.fold<double>(
            0,
            (s, i) => s + ((i['product']?['price'] as num? ?? 0) * (i['quantity'] as num? ?? 1)),
          );

          if (_upiDetails != null) {
            return _buildUpiStep(total);
          }

          return Column(children: [
            Expanded(
              child: ListView(padding: const EdgeInsets.all(20), children: [
                const Text('Store Pickup Time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _pickupTime,
                      isExpanded: true,
                      icon: const Icon(Icons.storefront_outlined, color: AppColors.primary),
                      items: [
                        'Today, 10:00 AM - 12:00 PM',
                        'Today, 2:00 PM - 5:00 PM',
                        'Tomorrow, 9:00 AM - 12:00 PM',
                        'Tomorrow, 1:00 PM - 5:00 PM',
                      ].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
                      onChanged: _placing ? null : (v) { if (v != null) setState(() => _pickupTime = v); },
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text('Payment Method', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _methodCard('UPI', Icons.account_balance_wallet_outlined, 'UPI Pay')),
                    const SizedBox(width: 12),
                    Expanded(child: _methodCard('COD', Icons.local_shipping_outlined, 'Cash on Delivery')),
                  ],
                ),
                const SizedBox(height: 32),
                _orderSummary(items, total),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                ],
              ]),
            ),
            _bottomBar(
              label: _paymentMethod == 'COD'
                  ? 'Confirm COD Order • ₹${total.toStringAsFixed(0)}'
                  : 'Continue with UPI • ₹${total.toStringAsFixed(0)}',
              onTap: _placeOrder,
            ),
          ]);
        },
      ),
    );
  }

  Widget _buildUpiStep(double total) {
    final suppliers = (_upiDetails!['suppliers'] as List?) ?? [];
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Pay via UPI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Pay ₹${total.toStringAsFixed(0)} to the supplier UPI ID below, then enter your UTR number.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 20),
              ...suppliers.map((s) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s['businessName'] ?? 'Supplier', style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text('UPI: ${s['upiId'] ?? 'Not set — contact supplier'}', style: const TextStyle(fontSize: 14)),
                    Text('Amount: ₹${(s['subtotal'] as num?)?.toStringAsFixed(0) ?? '0'}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              )),
              const SizedBox(height: 16),
              TextField(
                controller: _utrCtrl,
                decoration: const InputDecoration(
                  labelText: 'UTR / Transaction Reference',
                  hintText: 'Enter 12-digit UTR from UPI app',
                  prefixIcon: Icon(Icons.receipt_long_outlined),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ],
            ],
          ),
        ),
        _bottomBar(label: 'Submit UTR & Confirm Order', onTap: _submitUtr),
      ],
    );
  }

  Widget _methodCard(String method, IconData icon, String label) {
    final selected = _paymentMethod == method;
    return GestureDetector(
      onTap: _placing ? null : () => setState(() => _paymentMethod = method),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Column(children: [
          Icon(icon, color: selected ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: TextStyle(
            color: selected ? AppColors.primaryDark : AppColors.textSecondary,
            fontWeight: FontWeight.w700, fontSize: 12,
          )),
        ]),
      ),
    );
  }

  Widget _orderSummary(List items, double total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Order Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          ),
          child: Column(
            children: [
              ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(children: [
                  Expanded(child: Text(item['product']?['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Text('${item['quantity']}×', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(width: 12),
                  Text('₹${((item['product']?['price'] as num? ?? 0) * (item['quantity'] as num? ?? 1)).toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                ]),
              )),
              const Divider(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Total Amount', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                Text('₹${total.toStringAsFixed(0)}', style: AppTextStyles.price),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bottomBar({required String label, required VoidCallback onTap}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -10))],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            onPressed: _placing ? null : onTap,
            child: _placing
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
