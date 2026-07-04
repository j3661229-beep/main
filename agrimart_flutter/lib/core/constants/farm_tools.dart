import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class FarmToolItem {
  final String emoji;
  final String label;
  final String subtitle;
  final String route;
  final String category;
  final Color accent;
  final Color tint;
  final bool featured;

  const FarmToolItem({
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.route,
    required this.category,
    required this.accent,
    required this.tint,
    this.featured = false,
  });
}

const kFarmToolCategories = [
  'Market Intel',
  'AI & Advisory',
  'Schemes & Finance',
  'Trade & Rent',
];

const kFarmTools = [
  FarmToolItem(
    emoji: '📊',
    label: 'Mandi Prices',
    subtitle: 'Live APMC rates',
    route: '/farmer/mandi-prices',
    category: 'Market Intel',
    accent: AppColors.farmerAccent,
    tint: AppColors.farmerTint,
    featured: true,
  ),
  FarmToolItem(
    emoji: '🔔',
    label: 'Price Alerts',
    subtitle: 'Target notifications',
    route: '/farmer/price-alerts',
    category: 'Market Intel',
    accent: AppColors.warning,
    tint: AppColors.warningTint,
    featured: true,
  ),
  FarmToolItem(
    emoji: '🏛️',
    label: 'Govt Schemes',
    subtitle: 'Subsidies & loans',
    route: '/farmer/schemes',
    category: 'Schemes & Finance',
    accent: AppColors.info,
    tint: AppColors.infoTint,
    featured: true,
  ),
  FarmToolItem(
    emoji: '🧪',
    label: 'Soil Test',
    subtitle: 'AI soil analysis',
    route: '/farmer/soil',
    category: 'AI & Advisory',
    accent: AppColors.organic,
    tint: AppColors.successTint,
    featured: true,
  ),
  FarmToolItem(
    emoji: '🤖',
    label: 'Kisan AI',
    subtitle: 'Chat assistant',
    route: '/farmer/kisan-ai',
    category: 'AI & Advisory',
    accent: AppColors.supplierAccent,
    tint: AppColors.supplierTint,
    featured: true,
  ),
  FarmToolItem(
    emoji: '📅',
    label: 'Crop Calendar',
    subtitle: 'Sowing guide',
    route: '/farmer/crop-calendar',
    category: 'AI & Advisory',
    accent: AppColors.farmerAccent,
    tint: AppColors.farmerTint,
    featured: true,
  ),
  FarmToolItem(
    emoji: '🛡️',
    label: 'PMFBY',
    subtitle: 'Crop insurance',
    route: '/farmer/pmfby',
    category: 'Schemes & Finance',
    accent: AppColors.dealerAccent,
    tint: AppColors.dealerTint,
  ),
  FarmToolItem(
    emoji: '👥',
    label: 'FPO Bulk',
    subtitle: 'Collective selling',
    route: '/farmer/fpo-bulk',
    category: 'Schemes & Finance',
    accent: AppColors.farmerAccent,
    tint: AppColors.farmerTint,
  ),
  FarmToolItem(
    emoji: '🚜',
    label: 'Equipment',
    subtitle: 'Rent tractors',
    route: '/farmer/equipment',
    category: 'Trade & Rent',
    accent: AppColors.equipment,
    tint: AppColors.dealerTint,
  ),
  FarmToolItem(
    emoji: '📋',
    label: 'My Bookings',
    subtitle: 'Trade slots',
    route: '/farmer/trade/bookings',
    category: 'Trade & Rent',
    accent: AppColors.dealerAccent,
    tint: AppColors.dealerTint,
  ),
  FarmToolItem(
    emoji: '🌾',
    label: 'Crop Advisor',
    subtitle: 'What to grow',
    route: '/farmer/crop-advisor',
    category: 'AI & Advisory',
    accent: AppColors.organic,
    tint: AppColors.successTint,
  ),
  FarmToolItem(
    emoji: '☁️',
    label: 'Weather',
    subtitle: 'Farm advisory',
    route: '/farmer/advisory',
    category: 'AI & Advisory',
    accent: AppColors.info,
    tint: AppColors.infoTint,
  ),
];

List<FarmToolItem> featuredFarmTools() =>
    kFarmTools.where((t) => t.featured).toList();

List<FarmToolItem> farmToolsByCategory(String category) =>
    kFarmTools.where((t) => t.category == category).toList();
