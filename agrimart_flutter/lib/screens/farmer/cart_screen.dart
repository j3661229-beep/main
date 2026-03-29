import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('🛒 Cart'), backgroundColor: AppColors.primary),
      body: cart.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Could not load cart')),
        data: (data) {
          final items = data['items'] as List? ?? [];
          if (items.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('🛒', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text('Cart is empty', style: AppTextStyles.headingLG),
            const SizedBox(height: 8),
            TextButton(onPressed: () => context.go('/farmer/shop'), child: const Text('Start Shopping →')),
          ]));

          final total = items.fold<double>(0, (sum, item) => sum + ((item['product']?['price'] as num? ?? 0) * (item['quantity'] as num? ?? 1)));

          return Column(children: [
            Expanded(child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final item = items[i] as Map;
                final product = item['product'] as Map? ?? {};
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                  child: Row(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(width: 64, height: 64, color: AppColors.primarySurface, child: const Center(child: Text('🌿', style: TextStyle(fontSize: 30)))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(product['name'] ?? '', style: AppTextStyles.headingSM, maxLines: 2),
                      Text('₹${product['price']} /${product['unit']}', style: AppTextStyles.priceSmall.copyWith(fontSize: 14)),
                    ])),
                    // Qty control
                    Row(children: [
                      _QtyBtn(icon: Icons.remove, onTap: () {
                        if ((item['quantity'] as int) <= 1) {
                          ref.read(cartProvider.notifier).removeItem(item['id']);
                        } else {
                          ref.read(cartProvider.notifier).updateItem(item['id'], (item['quantity'] as int) - 1);
                        }
                      }),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text('${item['quantity']}', style: AppTextStyles.headingMD)),
                      _QtyBtn(icon: Icons.add, onTap: () => ref.read(cartProvider.notifier).updateItem(item['id'], (item['quantity'] as int) + 1)),
                    ]),
                  ]),
                );
              },
            )),

            // Checkout bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surface, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -4))]),
              child: SafeArea(child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Total', style: AppTextStyles.headingLG),
                  Text('₹${total.toStringAsFixed(0)}', style: AppTextStyles.price),
                ]),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => context.push('/farmer/checkout'),
                  child: const Text('Proceed to Checkout →'),
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
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(width: 30, height: 30, decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.primaryBorder)),
      child: Icon(icon, size: 18, color: AppColors.primary)),
  );
}
