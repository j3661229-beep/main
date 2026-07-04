import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/providers/app_providers.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(productId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.farmerAccent)),
        error: (e, _) => Scaffold(
          appBar: AppBar(leading: GestureDetector(onTap: () => context.pop(), child: const Icon(Icons.arrow_back_rounded))),
          body: Center(child: Text('Could not load product', style: GoogleFonts.inter(color: AppColors.muted))),
        ),
        data: (product) {
          final name        = product['name'] ?? 'Product';
          final description = product['description'] ?? '';
          final price       = (product['price'] as num?) ?? 0;
          final unit        = product['unit'] ?? 'unit';
          final stock       = product['stockQuantity'] ?? product['stock'] ?? 0;
          final supplier    = product['supplier']?['businessName'] ?? 'Supplier';
          final category    = product['category'] ?? '';
          final images      = (product['images'] as List?)?.cast<String>() ?? [];
          final imageUrl    = product['imageUrl'] ?? (images.isNotEmpty ? images[0] : null);

          return CustomScrollView(
            slivers: [
              // ── Image SliverAppBar ─────────────────────
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: AppColors.farmerAccent,
                leading: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: imageUrl != null
                      ? CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: AppColors.farmerTint, child: const Center(child: Text('🌱', style: TextStyle(fontSize: 80)))),
                          errorWidget: (_, __, ___) => Container(color: AppColors.farmerTint, child: const Center(child: Text('🌱', style: TextStyle(fontSize: 80)))))
                      : Container(color: AppColors.farmerTint, child: const Center(child: Text('🌱', style: TextStyle(fontSize: 80)))),
                ),
              ),

              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Details ───────────────────────────
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppColors.softShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (category.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: AppColors.farmerTint, borderRadius: BorderRadius.circular(20)),
                              child: Text(category, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.farmerAccent)),
                            ),
                          Text(name, style: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(formatRupee(price), style: GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.farmerAccent)),
                              const SizedBox(width: 6),
                              Text('/ $unit', style: GoogleFonts.inter(fontSize: 14, color: AppColors.muted)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _InfoPill(label: 'Sold by', value: supplier),
                              const SizedBox(width: 10),
                              _InfoPill(label: 'Stock', value: '$stock units', color: stock > 0 ? AppColors.success : AppColors.danger),
                            ],
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Divider(color: AppColors.border),
                            const SizedBox(height: 12),
                            Text('Description', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted)),
                            const SizedBox(height: 8),
                            Text(description, style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink, height: 1.6)),
                          ],
                        ],
                      ),
                    ),

                    // ── Add to Cart ───────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: Column(
                        children: [
                          AppButton(
                            label: 'Add to Cart',
                            onTap: stock > 0 ? () {
                              ref.read(cartProvider.notifier).addItem(Map<String, dynamic>.from(product), 1);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Added to cart ✓', style: GoogleFonts.inter(color: Colors.white)),
                                backgroundColor: AppColors.farmerAccent,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                duration: const Duration(seconds: 1),
                              ));
                            } : null,
                            color: AppColors.farmerAccent,
                            icon: Icons.add_shopping_cart_outlined,
                          ),
                          const SizedBox(height: 10),
                          AppButton(
                            label: 'Buy Now',
                            onTap: stock > 0 ? () {
                              ref.read(cartProvider.notifier).addItem(Map<String, dynamic>.from(product), 1);
                              context.push('/farmer/cart');
                            } : null,
                            color: AppColors.farmerAccent,
                            isOutlined: true,
                            icon: Icons.flash_on_rounded,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label, value;
  final Color? color;
  const _InfoPill({required this.label, required this.value, this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.border),
    ),
    child: RichText(
      text: TextSpan(
        children: [
          TextSpan(text: '$label: ', style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
          TextSpan(text: value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: color ?? AppColors.ink)),
        ],
      ),
    ),
  );
}

