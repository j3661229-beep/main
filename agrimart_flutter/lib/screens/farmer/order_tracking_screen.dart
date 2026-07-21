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
import '../../core/utils/responsive.dart';

class OrderTrackingScreen extends ConsumerWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.r;
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
    final r = context.r;
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
      padding: EdgeInsets.all(r.rs(20)),
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

        SizedBox(height: r.rh(20)),

        // ── Progress Bar ──────────────────────────────────────────────
        _ProgressCard(progressPercent: progressPercent, l10n: l10n),

        SizedBox(height: r.rh(24)),

        // ── Tracking Timeline ─────────────────────────────────────────
        Text(l10n.trackingHistory, style: AppTextStyles.headingLG),
        SizedBox(height: r.rh(16)),

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
            l10n: l10n,
          );
        }),

        SizedBox(height: r.rh(24)),

        // ── Order Items Summary ───────────────────────────────────────
        if (items.isNotEmpty) ...[
          Text(l10n.orderItems, style: AppTextStyles.headingLG),
          SizedBox(height: r.rh(12)),
          ...items.map((item) => _OrderItemRow(item: item as Map)),
        ],

        SizedBox(height: r.rh(80)),
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
    final r = context.r;
    final hasNavigation = supplierLat != null || mapCoords != null || address.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(r.rs(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: r.rs(20),
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(r.rs(20), r.rh(20), r.rs(20), r.rh(0)),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(r.rs(10)),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(r.rs(14)),
                  ),
                  child: Text('🏬', style: TextStyle(fontSize: r.sp(28))),
                ),
                SizedBox(width: r.rs(14)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.pickupLocation,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: r.sp(12),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: r.rh(2)),
                      Text(
                        storeName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: r.sp(18),
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
              padding: EdgeInsets.fromLTRB(r.rs(20), r.rh(12), r.rs(20), r.rh(0)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_pin, color: Colors.white70, size: r.sp(16)),
                  SizedBox(width: r.rs(6)),
                  Expanded(
                    child: Text(
                      address,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: r.sp(13),
                        height: r.rh(1.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(height: r.rh(16)),

          // Navigate Button
          if (hasNavigation)
            Padding(
              padding: EdgeInsets.fromLTRB(r.horizontalPadding, 0, r.horizontalPadding, 16),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(r.rs(14)),
                child: InkWell(
                  onTap: () => _openMaps(context),
                  borderRadius: BorderRadius.circular(r.rs(14)),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: r.rs(20), vertical: r.rh(14)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions, color: AppColors.primary, size: r.sp(22)),
                        SizedBox(width: r.rs(10)),
                        Text(
                          l10n.navigateToStore,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: r.sp(15),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(width: r.rs(6)),
                        Text('🗺️', style: TextStyle(fontSize: r.sp(16))),
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
    final r = context.r;
    return Container(
      padding: EdgeInsets.all(r.rs(20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r.rs(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: r.rs(15),
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
                width: r.rs(44),
                height: r.rh(44),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(r.rs(12)),
                ),
                child: Center(child: Text('📦', style: TextStyle(fontSize: r.sp(22)))),
              ),
              SizedBox(width: r.rs(14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.pickupProgress,
                      style: TextStyle(
                        fontSize: r.sp(12),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: r.rh(2)),
                    Text(
                      '$progressPercent% ${l10n.ready}',
                      style: TextStyle(
                        fontSize: r.sp(20),
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: r.rh(16)),
          ClipRRect(
            borderRadius: BorderRadius.circular(r.rs(8)),
            child: LinearProgressIndicator(
              value: progressPercent / 100,
              backgroundColor: AppColors.primarySurface,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: r.rh(10),
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
  final AppLocalizations l10n;

  const _TimelineStep({
    required this.label,
    required this.completed,
    required this.current,
    required this.isLast,
    required this.l10n,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    Color dotColor = completed
        ? (current ? AppColors.warning : AppColors.primary)
        : AppColors.border;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Column
          SizedBox(width: r.rs(32),
            child: Column(
              children: [
                Container(
                  width: r.rs(32),
                  height: r.rh(32),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: completed ? dotColor : Colors.transparent,
                    border: completed ? null : Border.all(color: AppColors.border, width: 2),
                    boxShadow: current
                        ? [BoxShadow(color: dotColor.withValues(alpha: 0.3), blurRadius: r.rs(8), spreadRadius: r.rs(2))]
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
                        width: r.rs(2),
                        margin: EdgeInsets.symmetric(vertical: r.rh(4)),
                        decoration: BoxDecoration(
                          color: completed ? AppColors.primary : AppColors.border.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(r.rs(1)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          SizedBox(width: r.rs(16)),

          // Label + timestamp
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: r.rh(6), bottom: isLast ? 0 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: current
                        ? TextStyle(
                            fontSize: r.sp(14),
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryDark,
                            letterSpacing: 0.5,
                          )
                        : TextStyle(
                            fontSize: r.sp(14),
                            fontWeight: FontWeight.w600,
                            color: completed ? AppColors.textPrimary : AppColors.textSecondary,
                            letterSpacing: 0.3,
                          ),
                  ),
                  if (timestamp != null && timestamp!.isNotEmpty) ...[
                    SizedBox(height: r.rh(4)),
                    Text(
                      _formatTimestamp(timestamp!),
                      style: TextStyle(
                        fontSize: r.sp(11),
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (current) ...[
                    SizedBox(height: r.rh(6)),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: r.rs(10), vertical: r.rh(4)),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(r.rs(20)),
                        border: Border.all(color: AppColors.primaryBorder),
                      ),
                      child: Text(
                        '● ${l10n.currentStep}',
                        style: TextStyle(
                          fontSize: r.sp(9),
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
    final r = context.r;
    final product = item['product'] as Map? ?? {};
    final name = product['name']?.toString() ?? item['name']?.toString() ?? 'Product';
    final qty = item['quantity']?.toString() ?? '1';
    final price = product['price']?.toString() ?? item['price']?.toString() ?? '0';
    final unit = product['unit']?.toString() ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: r.rh(10)),
      padding: EdgeInsets.symmetric(horizontal: r.rs(16), vertical: r.rh(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r.rs(14)),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: r.rs(44),
            height: r.rh(44),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(r.rs(10)),
            ),
            child: Center(child: Text('🌿', style: TextStyle(fontSize: r.sp(22)))),
          ),
          SizedBox(width: r.rs(14)),
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

