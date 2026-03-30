// Checkout Screen — Razorpay payment flow
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../data/providers/app_providers.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shimmer.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});
  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String _pickupTime = 'Today, 10:00 AM - 12:00 PM';
  late Razorpay _razorpay;
  bool _placing = false;
  String? _pendingOrderId;
  String _paymentMethod = 'RAZORPAY';

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    setState(() => _placing = true);
    try {
      // 1. Create order
      // We send the _pickupTime to the backend in the deliveryAddress field to fulfill BOPIS logic without schema changes
      final order = await ApiService.instance
          .createOrder(deliveryAddress: 'In-Store Pickup: $_pickupTime');
      _pendingOrderId = order['id'] as String;
      if (_paymentMethod == 'COD') {
        await ApiService.instance.confirmCashOnDelivery(_pendingOrderId!);
        ref.read(cartProvider.notifier).clear();
        if (!mounted) return;
        setState(() => _placing = false);
        context.go('/farmer/orders');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ Order placed with Cash on Delivery'),
            backgroundColor: AppColors.success));
        return;
      }

      // 2. Create Razorpay order
      final rpOrder =
          await ApiService.instance.createRazorpayOrder(_pendingOrderId!);
      final phone = ref.read(authProvider).user?.phone;
      _razorpay.open({
        'key': rpOrder['keyId'],
        'amount': rpOrder['amount'],
        'order_id': rpOrder['razorpayOrderId'],
        'name': 'AgriMart',
        'description': 'Agri Input Purchase',
        'prefill': {
          'contact': phone != null && phone.length > 3 ? phone.substring(3) : ''
        },
        'theme': {'color': '#2d6a4f'},
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _placing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'), backgroundColor: AppColors.error));
    }
  }

  void _onPaymentSuccess(PaymentSuccessResponse r) async {
    await ApiService.instance.verifyPayment(
        razorpayOrderId: r.orderId!,
        razorpayPaymentId: r.paymentId!,
        signature: r.signature!);
    ref.read(cartProvider.notifier).clear();
    if (!mounted) return;
    setState(() => _placing = false);
    context.go('/farmer/orders');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('🎉 Order placed successfully!'),
        backgroundColor: AppColors.success));
  }

  void _onPaymentError(PaymentFailureResponse r) {
    setState(() => _placing = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Payment failed: ${r.message}'),
        backgroundColor: AppColors.error));
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
          title: const Text('💳 Checkout', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)), 
          backgroundColor: AppColors.primary,
          elevation: 0,
          centerTitle: true),
      body: cart.when(
        loading: () => const AppShimmerList(itemCount: 4),
        error: (e, _) => const Center(child: Text('Cart error')),
        data: (data) {
          final items = data['items'] as List? ?? [];
          final total = items.fold<double>(
              0,
              (s, i) =>
                  s +
                  ((i['product']?['price'] as num? ?? 0) *
                      (i['quantity'] as num? ?? 1)));
          return Column(children: [
            Expanded(
                child: ListView(padding: const EdgeInsets.all(20), children: [
              const Text('Store Pickup Time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
                  ]
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
                    onChanged: (v) {
                      if (v != null) setState(() => _pickupTime = v);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text('Payment Method', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _placing ? null : () => setState(() => _paymentMethod = 'RAZORPAY'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _paymentMethod == 'RAZORPAY' ? AppColors.primarySurface : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _paymentMethod == 'RAZORPAY' ? AppColors.primary : AppColors.border),
                        ),
                        child: Column(children: [
                          Icon(Icons.payment, color: _paymentMethod == 'RAZORPAY' ? AppColors.primary : AppColors.textSecondary),
                          const SizedBox(height: 8),
                          Text('Online Pay', style: TextStyle(
                            color: _paymentMethod == 'RAZORPAY' ? AppColors.primaryDark : AppColors.textSecondary,
                            fontWeight: FontWeight.w700, fontSize: 13
                          ))
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _placing ? null : () => setState(() => _paymentMethod = 'COD'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _paymentMethod == 'COD' ? AppColors.primarySurface : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _paymentMethod == 'COD' ? AppColors.primary : AppColors.border),
                        ),
                        child: Column(children: [
                          Icon(Icons.local_shipping_outlined, color: _paymentMethod == 'COD' ? AppColors.primary : AppColors.textSecondary),
                          const SizedBox(height: 8),
                          Text('Cash on Delivery', style: TextStyle(
                            color: _paymentMethod == 'COD' ? AppColors.primaryDark : AppColors.textSecondary,
                            fontWeight: FontWeight.w700, fontSize: 13
                          ))
                        ]),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text('Order Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.5))),
                child: Column(
                  children: [
                    ...items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(children: [
                          Expanded(
                              child: Text(item['product']?['name'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          const SizedBox(width: 8),
                          Text('${item['quantity']}×', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          const SizedBox(width: 12),
                          Text(
                              '₹${((item['product']?['price'] as num? ?? 0) * (item['quantity'] as num? ?? 1)).toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        ]))),
                    const Divider(height: 24),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Total Amount', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                      Text('₹${total.toStringAsFixed(0)}',
                          style: AppTextStyles.price),
                    ]),
                  ],
                ),
              ),
            ])),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -10))
              ]),
              child: SafeArea(
                  child: Column(children: [
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    icon: _placing 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(_paymentMethod == 'COD' ? '📦' : '🔒'),
                    label: Text(_paymentMethod == 'COD'
                        ? 'Confirm COD Order • ₹${total.toStringAsFixed(0)}'
                        : 'Pay ₹${total.toStringAsFixed(0)} Now', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    onPressed: _placing ? null : _placeOrder,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _paymentMethod == 'COD'
                      ? 'Pay in cash at the time of delivery'
                      : 'UPI • Credit/Debit Card • Net Banking • Wallet',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ])),
            ),
          ]);
        },
      ),
    );
  }
}
