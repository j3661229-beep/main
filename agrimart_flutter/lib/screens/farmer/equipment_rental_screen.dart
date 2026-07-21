import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/agri_ui.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../data/providers/app_providers.dart';
import '../../core/utils/responsive.dart';

class EquipmentRentalScreen extends ConsumerWidget {
  const EquipmentRentalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.r;
    final products = ref.watch(equipmentProductsProvider);

    return AgriScreen(
      title: 'Equipment Rental',
      subtitle: 'Tractors, sprayers & tools',
      emoji: '🚜',
      onRefresh: () async => ref.invalidate(equipmentProductsProvider),
      body: products.when(
        loading: () => Padding(
          padding: EdgeInsets.all(r.rs(40)),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Padding(
          padding: EdgeInsets.all(r.rs(24)),
          child: Center(child: Text('Could not load: $e')),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              emoji: '🚜',
              title: 'No equipment listed yet',
              subtitle: 'Suppliers can list tractors, sprayers & tools under Equipment category',
            );
          }
          return Padding(
            padding: EdgeInsets.fromLTRB(r.horizontalPadding, 20, r.horizontalPadding, 32),
            child: Column(
              children: List.generate(list.length, (i) {
                final p = list[i] as Map;
                final name = p['name'] ?? 'Equipment';
                final price = p['price'] ?? 0;
                final unit = p['unit'] ?? 'day';
                final supplier = p['supplier']?['businessName'] ?? 'Supplier';
                return Padding(
                  padding: EdgeInsets.only(bottom: i < list.length - 1 ? 10 : 0),
                  child: AgriListTile(
                    emoji: '🔧',
                    title: name,
                    subtitle: '$supplier • ₹$price/$unit',
                    onTap: () => context.push('/farmer/market/product/${p['id']}'),
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }
}
