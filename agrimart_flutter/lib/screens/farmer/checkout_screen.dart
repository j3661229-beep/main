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
  final _addrCtrl = TextEditingController();
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
    _addrCtrl.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (_addrCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter delivery address')));
      return;
    }
    setState(() => _placing = true);
    try {
      // 1. Create order
      final order = await ApiService.instance
          .createOrder(deliveryAddress: _addrCtrl.text.trim());
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
      appBar: AppBar(
          title: const Text('💳 Checkout'), backgroundColor: AppColors.primary),
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
              const Text('Delivery Address', style: AppTextStyles.headingLG),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _addrCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      hintText:
                          'Enter complete delivery address with village, district, pincode…')),
              const SizedBox(height: 24),
              const Text('Order Summary', style: AppTextStyles.headingLG),
              const SizedBox(height: 12),
              const Text('Payment Method', style: AppTextStyles.labelLG),
              const SizedBox(height: 10),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                      value: 'RAZORPAY',
                      icon: Icon(Icons.payment),
                      label: Text('Razorpay')),
                  ButtonSegment(
                      value: 'COD',
                      icon: Icon(Icons.local_shipping_outlined),
                      label: Text('Cash on Delivery')),
                ],
                selected: {_paymentMethod},
                onSelectionChanged: _placing
                    ? null
                    : (s) => setState(() => _paymentMethod = s.first),
              ),
              const SizedBox(height: 20),
              ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Expanded(
                        child: Text(item['product']?['name'] ?? '',
                            style: AppTextStyles.bodyMD)),
                    Text('${item['quantity']}×', style: AppTextStyles.bodySM),
                    const SizedBox(width: 8),
                    Text(
                        '₹${((item['product']?['price'] as num? ?? 0) * (item['quantity'] as num? ?? 1)).toStringAsFixed(0)}',
                        style: AppTextStyles.headingSM),
                  ]))),
              const Divider(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Total Amount', style: AppTextStyles.headingLG),
                Text('₹${total.toStringAsFixed(0)}',
                    style: AppTextStyles.price),
              ]),
            ])),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surface, boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -4))
              ]),
              child: SafeArea(
                  child: Column(children: [
                ElevatedButton.icon(
                  icon: Text(_paymentMethod == 'COD' ? '📦' : '🔒'),
                  label: Text(_paymentMethod == 'COD'
                      ? 'Place COD Order • ₹${total.toStringAsFixed(0)}'
                      : 'Pay ₹${total.toStringAsFixed(0)} via Razorpay'),
                  onPressed: _placing ? null : _placeOrder,
                ),
                const SizedBox(height: 8),
                Text(
                  _paymentMethod == 'COD'
                      ? 'Pay in cash at the time of delivery'
                      : 'UPI • Credit/Debit Card • Net Banking • Wallet',
                  style: AppTextStyles.caption,
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
