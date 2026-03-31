import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers/app_providers.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final product = ref.watch(productDetailProvider(widget.productId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: product.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              AppShimmer(width: double.infinity, height: 280, borderRadius: 16),
              SizedBox(height: 16),
              AppShimmer(width: double.infinity, height: 24),
              SizedBox(height: 8),
              AppShimmer(width: 180, height: 16),
              SizedBox(height: 16),
              AppShimmer(width: double.infinity, height: 120),
            ],
          ),
        ),
        error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
        data: (p) => Stack(children: [
          CustomScrollView(slivers: [
            SliverAppBar(
              expandedHeight: 280,
              backgroundColor: AppColors.surface,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: AppColors.primarySurface,
                  child: p['images'] is List && (p['images'] as List).isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: p['images'][0],
                          memCacheWidth: 1000,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(color: Colors.white),
                          ),
                          errorWidget: (_, __, ___) => const Center(child: Text('🌿', style: TextStyle(fontSize: 80))),
                        )
                      : const Center(
                          child: Text('🌿', style: TextStyle(fontSize: 80))),
                ),
              ),
            ),
            SliverToBoxAdapter(
                child: Container(
              color: AppColors.background,
              child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                if (p['isOrganic'] == true)
                                  const Text('🌱 ORGANIC',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.success,
                                          letterSpacing: 0.5)),
                                Text(p['name'] ?? '',
                                    style: AppTextStyles.headingXL),
                                if (p['nameMarathi'] != null)
                                  Text(p['nameMarathi'],
                                      style: AppTextStyles.bodySM),
                              ])),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('₹${p['price']}',
                                    style: AppTextStyles.price),
                                Text('/${p['unit']}',
                                    style: AppTextStyles.caption),
                              ]),
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          _InfoChip('🏭 ${p['brand'] ?? 'N/A'}'),
                          const SizedBox(width: 8),
                          _InfoChip('📦 Stock: ${p['stockQuantity']}'),
                          const SizedBox(width: 8),
                          _InfoChip('🏬 In-Store Pickup'),
                        ]),
                        const SizedBox(height: 20),
                        const Text('Description',
                            style: AppTextStyles.headingMD),
                        const SizedBox(height: 6),
                        Text(
                          p['description'] ?? '',
                          style: AppTextStyles.bodyMD
                              .copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 100),
                      ])),
            )),
          ]),
          // Bottom add to cart
          Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.surface, boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, -4))
                ]),
                child: SafeArea(
                    child: Row(children: [
                  // Quantity Selector
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryBorder),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 20),
                          color: AppColors.primary,
                          onPressed: () {
                            if (_quantity > 1) {
                              setState(() => _quantity--);
                            }
                          },
                        ),
                        Text('$_quantity', style: AppTextStyles.headingMD),
                        IconButton(
                          icon: const Icon(Icons.add, size: 20),
                          color: AppColors.primary,
                          onPressed: () {
                            if (_quantity < (p['stockQuantity'] as int? ?? 99)) {
                              setState(() => _quantity++);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      try {
                        await ref
                            .read(cartProvider.notifier)
                            .addItem(Map<String, dynamic>.from(p), _quantity);
                            if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Reserved $_quantity unit(s) ✅'),
                                  backgroundColor: AppColors.primary));
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Failed: $e'),
                                  backgroundColor: AppColors.error));
                        }
                      }
                    },
                    child: const Text('Reserve for Pickup 🏬', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  )),
                ])),
              )),
        ]),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String text;
  const _InfoChip(this.text);
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryBorder)),
      child: Text(text,
          style: AppTextStyles.caption.copyWith(color: AppColors.primary)));
}
