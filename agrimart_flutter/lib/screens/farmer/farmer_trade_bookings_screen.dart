import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import '../../core/utils/responsive.dart';

class FarmerTradeBookingsScreen extends ConsumerWidget {
  const FarmerTradeBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.r;
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
                        padding: EdgeInsets.all(r.rs(24)),
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: AppColors.softShadow),
                        child: Text('📅', style: TextStyle(fontSize: r.sp(64))),
                      ),
                      SizedBox(height: r.rh(24)),
                      Text('No Booked Slots yet', style: AppTextStyles.headingLG),
                      SizedBox(height: r.rh(8)),
                      Text("You haven't booked any crop delivery\nslots with dealers.", 
                        style: AppTextStyles.bodyLG.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.all(r.rs(16)),
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
    final r = context.r;
    final dealer = booking['dealer']?['businessName'] ?? booking['dealer']?['user']?['name'] ?? 'Authorized Dealer';
    final statusColor = booking['status'] == 'ACCEPTED' ? AppColors.success : (booking['status'] == 'CANCELLED' ? AppColors.error : AppColors.warning);
    final slotDate = DateTime.tryParse(booking['slotDate'] ?? '');

    return Container(
      margin: EdgeInsets.only(bottom: r.rh(16)),
      padding: EdgeInsets.all(r.rs(20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r.rs(20)),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(r.rs(10)),
                decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(r.rs(12))),
                child: Text('🌾', style: TextStyle(fontSize: r.sp(24))),
              ),
              SizedBox(width: r.rs(12)),
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
                padding: EdgeInsets.symmetric(horizontal: r.rs(10), vertical: r.rh(4)),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(r.rs(20))),
                child: Text(booking['status'] ?? '', style: TextStyle(color: statusColor, fontSize: r.sp(10), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          Divider(height: r.rh(32)),
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
    final r = context.r;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        SizedBox(height: r.rh(2)),
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
    final r = context.r;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(r.rs(32)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('⚠️', style: TextStyle(fontSize: r.sp(48))),
            SizedBox(height: r.rh(16)),
            Text('Oops! Something went wrong', style: AppTextStyles.headingMD),
            SizedBox(height: r.rh(8)),
            Text(message, style: AppTextStyles.bodySM, textAlign: TextAlign.center),
            SizedBox(height: r.rh(24)),
            ElevatedButton(onPressed: onRetry, child: Text('Try Again')),
          ],
        ),
      ),
    );
  }
}

