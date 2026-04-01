import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/services/api_service.dart';
import '../../data/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_fallback.dart';
import '../../core/widgets/app_shimmer.dart';
import '../../core/widgets/app_snackbar.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
          title: const Text('🛒 My Cart', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)), 
          backgroundColor: AppColors.primary,
          elevation: 0,
          centerTitle: true),
      body: cart.when(
        loading: () => const AppShimmerList(itemCount: 5),
        error: (e, _) => AppErrorState(
          message: e.toString(),
          onRetry: () => ref.read(cartProvider.notifier).load(),
        ),
        data: (data) {
          final items = data['items'] as List? ?? [];
          if (items.isEmpty) {
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => ref.read(cartProvider.notifier).load(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.65,
                    child: AppEmptyState(
                      icon: '🛒',
                      title: 'Your cart is empty',
                      subtitle:
                          'Browse the shop and add seeds, fertilizer, and more.',
                      actionLabel: 'Browse shop',
                      onAction: () => context.go('/farmer/shop'),
                    ),
                  ),
                ],
              ),
            );
          }

          final total = items.fold<double>(
              0,
              (sum, item) =>
                  sum +
                  ((item['product']?['price'] as num? ?? 0) *
                      (item['quantity'] as num? ?? 1)));

          return Column(children: [
            Expanded(
                child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => ref.read(cartProvider.notifier).load(),
              child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final item = items[i] as Map;
                final product = item['product'] as Map? ?? {};
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4)
                        )
                      ],
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.5))),
                  child: Row(children: [
                    Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(16)
                        ),
                        child: const Center(
                            child:
                                Text('🌿', style: TextStyle(fontSize: 32)))),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(product['name'] ?? '',
                              style: AppTextStyles.headingSM.copyWith(height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text('₹${product['price']} /${product['unit']}',
                              style: AppTextStyles.priceSmall
                                  .copyWith(fontSize: 13, color: AppColors.textSecondary)),
                        ])),
                    const SizedBox(width: 8),
                    // Qty control
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                        _QtyBtn(
                            icon: Icons.remove,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              final currentQty = (item['quantity'] as num).toInt();
                              if (currentQty <= 1) {
                                ref
                                    .read(cartProvider.notifier)
                                    .removeItem(item['id']);
                              } else {
                                ref.read(cartProvider.notifier).updateItem(
                                    item['id'], currentQty - 1);
                              }
                            }),
                        Container(
                          width: 32,
                          alignment: Alignment.center,
                          child: Text('${item['quantity']}',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                        ),
                        _QtyBtn(
                            icon: Icons.add,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              ref.read(cartProvider.notifier).updateItem(
                                  item['id'],
                                  (item['quantity'] as num).toInt() + 1);
                            }),
                      ]),
                    ),
                  ]),
                );
              },
            ),
            )),

            // Checkout bar
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
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total to Pay', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                      Text('₹${total.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: AppColors.primaryDark)),
                    ]),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      // Sync local cart to backend before checkout
                      try {
                        // show loading dialog
                        showDialog(
                          context: context, 
                          barrierDismissible: false,
                          builder: (_) => const Center(child: CircularProgressIndicator())
                        );
                        final api = ApiService.instance;
                        await api.clearCart();
                        for (final item in items) {
                           await api.addToCart(
                             productId: item['product']?['id'] ?? item['product']?['_id'] ?? item['productId'], 
                             quantity: item['quantity']
                           );
                        }
                        if (context.mounted) {
                          Navigator.pop(context); // hide loading
                          context.push('/farmer/checkout');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.pop(context); // hide loading
                          AppSnackbar.error(
                              context, 'Could not sync cart. Please try again.');
                        }
                      }
                    },
                    child: const Text('Proceed to Checkout →', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ),
                ),
              ])),
            ),
          ]);
        },
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 18, color: AppColors.primaryDark),
          ),
        ),
      );
}
