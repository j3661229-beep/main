import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class FarmerTradeBookingsScreen extends ConsumerWidget {
  const FarmerTradeBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(farmerTradeBookingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Delivery Slots'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(farmerTradeBookingsProvider),
        child: bookings.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => _ErrorState(message: e.toString(), onRetry: () => ref.invalidate(farmerTradeBookingsProvider)),
          data: (list) {
            if (list.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: AppColors.softShadow),
                        child: const Text('📅', style: TextStyle(fontSize: 64)),
                      ),
                      const SizedBox(height: 24),
                      Text('No Booked Slots yet', style: AppTextStyles.headingLG),
                      const SizedBox(height: 8),
                      Text("You haven't booked any crop delivery\nslots with dealers.", 
                        style: AppTextStyles.bodyLG.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (ctx, i) => _BookingCard(booking: list[i]),
            );
          },
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Map booking;
  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final dealer = booking['dealer']?['businessName'] ?? booking['dealer']?['user']?['name'] ?? 'Authorized Dealer';
    final statusColor = booking['status'] == 'ACCEPTED' ? AppColors.success : (booking['status'] == 'CANCELLED' ? AppColors.error : AppColors.amber);
    final slotDate = DateTime.tryParse(booking['slotDate'] ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(12)),
                child: const Text('🌾', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking['cropName'] ?? '', style: AppTextStyles.headingMD),
                    Text('To: $dealer', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(booking['status'] ?? '', style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _DetailCol(label: 'Approx Qty', value: '${booking['approxQuintals']}Q'),
              _DetailCol(label: 'Expected Rate', value: '₹${booking['pricePerQuintal']}'),
              _DetailCol(label: 'Delivery Date', value: slotDate != null ? DateFormat('d MMM yy').format(slotDate) : '--'),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailCol extends StatelessWidget {
  final String label, value;
  const _DetailCol({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.labelMD),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('Oops! Something went wrong', style: AppTextStyles.headingMD),
            const SizedBox(height: 8),
            Text(message, style: AppTextStyles.bodySM, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onRetry, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }
}
