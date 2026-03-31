import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class FloatingDockNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;
  final List<FloatingNavItem> items;

  const FloatingDockNav({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isSelected = selectedIndex == index;

                return _NavItem(
                  item: item,
                  isSelected: isSelected,
                  onTap: () => onTabSelected(index),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final FloatingNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap();
        // Feedback
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuint,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Text(
                item.icon,
                style: TextStyle(
                  fontSize: 24,
                  color: isSelected ? AppColors.primary : AppColors.textTertiary,
                ),
              ),
            ),
            const SizedBox(height: 2),
            AnimatedOpacity(
              opacity: isSelected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: isSelected 
                ? Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: -0.2,
                    ),
                  )
                : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class FloatingNavItem {
  final String icon;
  final String label;
  final int? badge;

  FloatingNavItem({
    required this.icon,
    required this.label,
    this.badge,
  });
}
