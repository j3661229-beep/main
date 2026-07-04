import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/providers/app_providers.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('My Cart', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w700)),
        leading: GestureDetector(onTap: () => context.pop(), child: const Icon(Icons.arrow_back_rounded)),
      ),
      body: cartAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.farmerAccent)),
        error: (e, _) => EmptyState(emoji: '⚠️', title: 'Could not load cart', subtitle: e.toString()),
        data: (cart) {
          final items = (cart['items'] as List?) ?? [];
          if (items.isEmpty) {
            return const EmptyState(emoji: '🛒', title: 'Cart is empty', subtitle: 'Add items from the market to continue');
          }

          // Calculate total
          double total = 0;
          for (final item in items) {
            final price = (item['product']?['price'] as num?) ?? (item['price'] as num?) ?? 0;
            final qty   = (item['quantity'] as num?) ?? 0;
            total += price * qty;
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _CartItem(item: items[i]),
                ),
              ),

              // ── Summary + Checkout ─────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: AppColors.deepShadow,
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Subtotal (${items.length} items)', style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted)),
                          Text(formatRupee(total), style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Delivery', style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted)),
                          Text(total >= 500 ? 'FREE' : formatRupee(50), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.success)),
                        ],
                      ),
                      const Divider(height: 20, color: AppColors.border),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total', style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
                          Text(formatRupee(total >= 500 ? total : total + 50), style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.farmerAccent)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        label: 'Proceed to Pay',
                        onTap: () => context.push('/farmer/payment'),
                        color: AppColors.farmerAccent,
                        icon: Icons.payment_outlined,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CartItem extends ConsumerWidget {
  final Map item;
  const _CartItem({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = item['product'] as Map? ?? {};
    final name    = product['name'] ?? item['productName'] ?? 'Product';
    final List? images = product['images'] as List?;
    final imageUrl = product['imageUrl'] ?? (images != null && images.isNotEmpty ? images[0] : null);
    final price   = (product['price'] as num?) ?? (item['price'] as num?) ?? 0;
    final qty     = (item['quantity'] as num?) ?? 1;
    final itemId  = item['id'] as String? ?? '';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: AppColors.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageUrl != null
                  ? CachedNetworkImage(imageUrl: imageUrl, width: 70, height: 70, fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(width: 70, height: 70, color: AppColors.farmerTint, child: const Center(child: Text('🌱', style: TextStyle(fontSize: 28)))))
                  : Container(width: 70, height: 70, color: AppColors.farmerTint, child: const Center(child: Text('🌱', style: TextStyle(fontSize: 28)))),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(formatRupee(price), style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.farmerAccent)),
                ],
              ),
            ),
            // Qty stepper
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _StepBtn(
                    icon: Icons.remove,
                    onTap: () {
                      if (qty <= 1) {
                        ref.read(cartProvider.notifier).removeItem(itemId);
                      } else {
                        ref.read(cartProvider.notifier).updateItem(itemId, qty.toInt() - 1);
                      }
                    },
                  ),
                  Container(
                    width: 32,
                    alignment: Alignment.center,
                    child: Text('$qty', style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
                  ),
                  _StepBtn(
                    icon: Icons.add,
                    onTap: () => ref.read(cartProvider.notifier).updateItem(itemId, qty.toInt() + 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 32, height: 32,
      alignment: Alignment.center,
      child: Icon(icon, size: 18, color: AppColors.farmerAccent),
    ),
  );
}

