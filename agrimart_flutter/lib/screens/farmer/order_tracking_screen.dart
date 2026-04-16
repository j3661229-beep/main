import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_fallback.dart';
import '../../core/widgets/app_shimmer.dart';
import '../../core/errors/app_exceptions.dart';
import 'package:agrimart/l10n/app_localizations.dart';

class OrderTrackingScreen extends ConsumerWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracking = ref.watch(orderTrackingProvider(orderId));
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '📍 ${l10n.orderTracking}',
          style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: tracking.when(
        loading: () => const AppShimmerList(),
        error: (e, _) => AppErrorState(
          message: extractUserFacingError(e),
          onRetry: () => ref.invalidate(orderTrackingProvider(orderId)),
        ),
        data: (data) => _TrackingBody(data: data, l10n: l10n),
      ),
    );
  }
}

class _TrackingBody extends StatelessWidget {
  final Map data;
  final AppLocalizations l10n;

  const _TrackingBody({required this.data, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final backendSteps = (data['tracking'] as List? ?? []);
    final order = data['order'] as Map? ?? {};
    final items = order['items'] as List? ?? [];

    // Extract store/supplier info from order items
    final supplier = items.isNotEmpty ? items.first['supplier'] : null;
    final storeName = supplier?['businessName']?.toString() ?? l10n.store;
    final rawAddress = supplier?['address']?.toString() ?? '';

    // Parse embedded map link if present: "Address | MAP: lat,lng"
    final parsedAddress = rawAddress.split(' | MAP: ');
    final cleanAddress = parsedAddress[0].trim();
    final mapCoords = parsedAddress.length > 1 ? parsedAddress[1].trim() : null;

    // Also check for explicit location fields on supplier
    final supplierLat = (supplier?['lat'] as num?)?.toDouble() ??
        (supplier?['latitude'] as num?)?.toDouble();
    final supplierLng = (supplier?['lng'] as num?)?.toDouble() ??
        (supplier?['longitude'] as num?)?.toDouble();

    final progressPercent = (data['progressPercent'] as num?)?.toInt() ?? 0;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Store / Pickup Location Card ──────────────────────────────
        _StoreLocationCard(
          storeName: storeName,
          address: cleanAddress,
          mapCoords: mapCoords,
          supplierLat: supplierLat,
          supplierLng: supplierLng,
          l10n: l10n,
        ),

        const SizedBox(height: 20),

        // ── Progress Bar ──────────────────────────────────────────────
        _ProgressCard(progressPercent: progressPercent, l10n: l10n),

        const SizedBox(height: 24),

        // ── Tracking Timeline ─────────────────────────────────────────
        Text(l10n.trackingHistory, style: AppTextStyles.headingLG),
        const SizedBox(height: 16),

        ...backendSteps.asMap().entries.map((e) {
          final step = e.value as Map;
          final label = step['label']?.toString() ?? '';
          final completed = step['completed'] == true;
          final current = step['current'] == true;
          final isLast = e.key == backendSteps.length - 1;
          return _TimelineStep(
            label: label,
            completed: completed,
            current: current,
            isLast: isLast,
            timestamp: step['timestamp']?.toString(),
          );
        }),

        const SizedBox(height: 24),

        // ── Order Items Summary ───────────────────────────────────────
        if (items.isNotEmpty) ...[
          Text(l10n.orderItems, style: AppTextStyles.headingLG),
          const SizedBox(height: 12),
          ...items.map((item) => _OrderItemRow(item: item as Map)),
        ],

        const SizedBox(height: 80),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Store Location Card with Maps Integration
// ─────────────────────────────────────────────────────────────────────────────

class _StoreLocationCard extends StatelessWidget {
  final String storeName;
  final String address;
  final String? mapCoords;
  final double? supplierLat;
  final double? supplierLng;
  final AppLocalizations l10n;

  const _StoreLocationCard({
    required this.storeName,
    required this.address,
    this.mapCoords,
    this.supplierLat,
    this.supplierLng,
    required this.l10n,
  });

  Future<void> _openMaps(BuildContext context) async {
    Uri? mapsUri;

    // Priority: embedded lat/lng > mapCoords string > address search
    if (supplierLat != null && supplierLng != null) {
      mapsUri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$supplierLat,$supplierLng&travelmode=driving',
      );
    } else if (mapCoords != null) {
      final parts = mapCoords!.split(',');
      if (parts.length == 2) {
        final lat = double.tryParse(parts[0].trim());
        final lng = double.tryParse(parts[1].trim());
        if (lat != null && lng != null) {
          mapsUri = Uri.parse(
            'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
          );
        }
      }
      // If mapCoords is a URL directly
      if (mapsUri == null && mapCoords!.startsWith('http')) {
        mapsUri = Uri.parse(mapCoords!);
      }
    } else if (address.isNotEmpty) {
      // Fallback: search by address name
      final encoded = Uri.encodeComponent('$storeName $address');
      mapsUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');
    }

    if (mapsUri == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.locationNotAvailable)),
        );
      }
      return;
    }

    if (await canLaunchUrl(mapsUri)) {
      await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
    } else {
      // Try native maps app as geo: uri
      final geoUri = supplierLat != null
          ? Uri.parse('geo:$supplierLat,$supplierLng?q=$supplierLat,$supplierLng($storeName)')
          : Uri.parse('geo:0,0?q=${Uri.encodeComponent(storeName)}');
      if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.mapsNotAvailable)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasNavigation = supplierLat != null || mapCoords != null || address.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text('🏬', style: TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.pickupLocation,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        storeName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (address.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_pin, color: Colors.white70, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      address,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Navigate Button
          if (hasNavigation)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () => _openMaps(context),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.directions, color: AppColors.primary, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          l10n.navigateToStore,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('🗺️', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Progress Card
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  final int progressPercent;
  final AppLocalizations l10n;

  const _ProgressCard({required this.progressPercent, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Text('📦', style: TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.pickupProgress,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$progressPercent% ${l10n.ready}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progressPercent / 100,
              backgroundColor: AppColors.primarySurface,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Timeline Step
// ─────────────────────────────────────────────────────────────────────────────

class _TimelineStep extends StatelessWidget {
  final String label;
  final bool completed;
  final bool current;
  final bool isLast;
  final String? timestamp;

  const _TimelineStep({
    required this.label,
    required this.completed,
    required this.current,
    required this.isLast,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    Color dotColor = completed
        ? (current ? AppColors.amber : AppColors.primary)
        : AppColors.border;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Column
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: completed ? dotColor : Colors.transparent,
                    border: completed ? null : Border.all(color: AppColors.border, width: 2),
                    boxShadow: current
                        ? [BoxShadow(color: dotColor.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 2)]
                        : null,
                  ),
                  child: Icon(
                    completed && !current ? Icons.check : (current ? Icons.circle : Icons.circle_outlined),
                    size: 16,
                    color: completed ? Colors.white : AppColors.border,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: completed ? AppColors.primary : AppColors.border.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Label + timestamp
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 6, bottom: isLast ? 0 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: current
                        ? const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryDark,
                            letterSpacing: 0.5,
                          )
                        : TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: completed ? AppColors.textPrimary : AppColors.textSecondary,
                            letterSpacing: 0.3,
                          ),
                  ),
                  if (timestamp != null && timestamp!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatTimestamp(timestamp!),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (current) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primaryBorder),
                      ),
                      child: const Text(
                        '● CURRENT',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(String ts) {
    try {
      final dt = DateTime.parse(ts).toLocal();
      final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
      final minute = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '${dt.day}/${dt.month}/${dt.year} $hour:$minute $ampm';
    } catch (_) {
      return ts;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Order Item Row
// ─────────────────────────────────────────────────────────────────────────────

class _OrderItemRow extends StatelessWidget {
  final Map item;
  const _OrderItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final product = item['product'] as Map? ?? {};
    final name = product['name']?.toString() ?? item['name']?.toString() ?? 'Product';
    final qty = item['quantity']?.toString() ?? '1';
    final price = product['price']?.toString() ?? item['price']?.toString() ?? '0';
    final unit = product['unit']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(child: Text('🌿', style: TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.headingSM, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('$qty × ₹$price $unit', style: AppTextStyles.caption),
              ],
            ),
          ),
          Text('₹${(double.tryParse(price) ?? 0) * (int.tryParse(qty) ?? 1)}',
              style: AppTextStyles.priceSmall),
        ],
      ),
    );
  }
}
