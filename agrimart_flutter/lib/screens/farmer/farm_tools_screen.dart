import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/farm_tools.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/agri_ui.dart';

class FarmToolsScreen extends StatelessWidget {
  final bool embedded;
  const FarmToolsScreen({super.key, this.embedded = false});

  Widget _content() => Padding(
        padding: EdgeInsets.fromLTRB(16, embedded ? 8 : 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (embedded) ...[
              Text(
                'Farm Toolkit',
                style: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink),
              ),
              const SizedBox(height: 4),
              Text('12 tools for your farm', style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted)),
              const SizedBox(height: 16),
            ],
            const InfoBanner(
              text: 'Tap any tool — mandi prices, AI crop doctor, govt schemes, insurance & equipment rental.',
              icon: Icons.touch_app_rounded,
            ),
            const SizedBox(height: 24),
            ...kFarmToolCategories.map((cat) {
              final tools = farmToolsByCategory(cat);
              if (tools.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 18,
                          decoration: BoxDecoration(
                            color: AppColors.farmerAccent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          cat,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FarmToolsGrid(tools: tools, crossAxisCount: 3),
                  ],
                ),
              );
            }),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (embedded) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: _content(),
          ),
        ),
      );
    }
    return AgriScreen(
      title: 'Farm Toolkit',
      subtitle: 'Everything you need on the field',
      emoji: '🧰',
      showBack: true,
      body: _content(),
    );
  }
}
