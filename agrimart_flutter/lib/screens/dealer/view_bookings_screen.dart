import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class DealerBookingsScreen extends StatelessWidget {
  const DealerBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Farmer Appointments'),
        backgroundColor: AppColors.primary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 24),
          _buildBookingTile(
            farmerName: 'Nitin Gaikwad',
            crop: 'Soyabean',
            quantity: '50 Quintals',
            date: 'Today, 2:00 PM',
            status: 'PENDING',
          ),
          _buildBookingTile(
            farmerName: 'Rahul Patil',
            crop: 'Cotton',
            quantity: '35 Quintals',
            date: 'Tomorrow, 10:00 AM',
            status: 'ACCEPTED',
          ),
          _buildBookingTile(
            farmerName: 'Sanjay More',
            crop: 'Wheat',
            quantity: '100 Quintals',
            date: '05 April, 11:30 AM',
            status: 'COMPLETED',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.primaryShadow,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem(label: 'Pending', value: '3', color: Colors.white),
          _SummaryItem(label: 'Today', value: '5', color: Colors.white),
          _SummaryItem(label: 'Total', value: '42', color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildBookingTile({
    required String farmerName,
    required String crop,
    required String quantity,
    required String date,
    required String status,
  }) {
    final statusColor = status == 'ACCEPTED' ? AppColors.success : (status == 'PENDING' ? AppColors.amber : Colors.grey);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(backgroundColor: AppColors.primarySurface, child: Text('👨‍🌾')),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(farmerName, style: AppTextStyles.headingMD),
                    Text(date, style: AppTextStyles.caption),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CropInfoItem(label: 'Crop', value: crop),
              _CropInfoItem(label: 'Approx Qty', value: quantity),
            ],
          ),
          if (status == 'PENDING') ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SummaryItem({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
      Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 12)),
    ],
  );
}

class _CropInfoItem extends StatelessWidget {
  final String label, value;
  const _CropInfoItem({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTextStyles.caption),
      Text(value, style: AppTextStyles.labelLG),
    ],
  );
}
