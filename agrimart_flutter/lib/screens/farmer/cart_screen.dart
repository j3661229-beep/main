import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:agrimart/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/agri_ui.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/providers/app_providers.dart';
import '../../core/utils/responsive.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.r;
    final l10n = AppLocalizations.of(context)!;
    final cartAsync = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          FarmerTabHeader(
            emoji: '🛒',
            title: l10n.myCart,
            showBack: true,
          ),
          Expanded(
            child: cartAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.farmerAccent)),
        error: (e, _) => EmptyState(emoji: '⚠️', title: l10n.couldNotLoadOrders, subtitle: e.toString()),
        data: (cart) {
          final items = (cart['items'] as List?) ?? [];
          if (items.isEmpty) {
            return EmptyState(emoji: '🛒', title: l10n.cartEmpty, subtitle: l10n.cartEmptySubtitle);
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
                  padding: EdgeInsets.all(r.rs(16)),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => SizedBox(height: r.rh(12)),
                  itemBuilder: (_, i) => _CartItem(item: items[i]),
                ),
              ),

              // Sticky checkout bar
              Container(
                padding: EdgeInsets.fromLTRB(r.rs(20), r.rs(16), r.rs(20), r.rs(12)),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(r.rs(24))),
                  boxShadow: AppColors.deepShadow,
                  border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.6))),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${l10n.subtotal} (${items.length})', style: GoogleFonts.inter(fontSize: r.sp(13), color: AppColors.muted)),
                          Text(formatRupee(total), style: GoogleFonts.spaceGrotesk(fontSize: r.sp(14), fontWeight: FontWeight.w600, color: AppColors.ink)),
                        ],
                      ),
                      SizedBox(height: r.rs(6)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.delivery, style: GoogleFonts.inter(fontSize: r.sp(13), color: AppColors.muted)),
                          Text(total >= 500 ? l10n.free : formatRupee(50), style: GoogleFonts.inter(fontSize: r.sp(13), fontWeight: FontWeight.w500, color: AppColors.success)),
                        ],
                      ),
                      Divider(height: r.rs(20), color: AppColors.border),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.total, style: GoogleFonts.spaceGrotesk(fontSize: r.sp(16), fontWeight: FontWeight.w700, color: AppColors.ink)),
                          Text(formatRupee(total >= 500 ? total : total + 50), style: GoogleFonts.spaceGrotesk(fontSize: r.sp(20), fontWeight: FontWeight.w800, color: AppColors.farmerAccent)),
                        ],
                      ),
                      SizedBox(height: r.rs(16)),
                      AppButton(
                        label: l10n.proceedToPay,
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
          ),
        ],
      ),
    );
  }
}

class _CartItem extends ConsumerWidget {
  final Map item;
  const _CartItem({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.r;
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
        borderRadius: BorderRadius.circular(r.rs(16)),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: AppColors.softShadow,
      ),
      child: Padding(
        padding: EdgeInsets.all(r.rs(14)),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(r.rs(12)),
              child: imageUrl != null
                  ? CachedNetworkImage(imageUrl: imageUrl, width: 70, height: 70, fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(width: 70, height: 70, color: AppColors.farmerTint, child: Center(child: Text('🌱', style: TextStyle(fontSize: r.sp(28))))))
                  : Container(width: 70, height: 70, color: AppColors.farmerTint, child: Center(child: Text('🌱', style: TextStyle(fontSize: r.sp(28))))),
            ),
            SizedBox(width: r.rs(12)),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: GoogleFonts.inter(fontSize: r.sp(14), fontWeight: FontWeight.w500, color: AppColors.ink), maxLines: 2, overflow: TextOverflow.ellipsis),
                  SizedBox(height: r.rh(4)),
                  Text(formatRupee(price), style: GoogleFonts.spaceGrotesk(fontSize: r.sp(14), fontWeight: FontWeight.w700, color: AppColors.farmerAccent)),
                ],
              ),
            ),
            // Qty stepper
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(r.rs(10)),
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
                    width: r.rs(32),
                    alignment: Alignment.center,
                    child: Text('$qty', style: GoogleFonts.spaceGrotesk(fontSize: r.sp(14), fontWeight: FontWeight.w600, color: AppColors.ink)),
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
  Widget build(BuildContext context) {
    final r = context.r;
    return GestureDetector(
    onTap: onTap,
    child: Container(
      width: r.rs(32), height: r.rh(32),
      alignment: Alignment.center,
      child: Icon(icon, size: r.sp(18), color: AppColors.farmerAccent),
    ),
  );
  }
}

