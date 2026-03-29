import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  static const _pages = [
    {'emoji': '🛒', 'title': 'थेट खरेदी करा', 'subtitle': 'Buy Direct', 'body': 'Buy seeds, fertilizers & pesticides directly from trusted suppliers at best market prices.', 'color': 0xFF2D6A4F},
    {'emoji': '🧪', 'title': 'माती तपासा', 'subtitle': 'AI Soil Analysis', 'body': 'Take a photo of your soil and get instant AI analysis with crop recommendations.', 'color': 0xFF4DAC7A},
    {'emoji': '📈', 'title': 'बाजार भाव', 'subtitle': 'Live Mandi Prices', 'body': 'Check live APMC mandi prices and set price alerts for your crops.', 'color': 0xFF1A4231},
    {'emoji': '🤖', 'title': 'किसान AI', 'subtitle': 'Kisan AI Assistant', 'body': 'Ask farming questions in Marathi, Hindi or English and get expert AI advice.', 'color': 0xFF2D6A4F},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        PageView.builder(
          controller: _pageCtrl,
          onPageChanged: (i) => setState(() => _page = i),
          itemCount: _pages.length,
          itemBuilder: (ctx, i) {
            final p = _pages[i];
            return Container(
              decoration: BoxDecoration(gradient: LinearGradient(
                colors: [Color(p['color'] as int), Color(p['color'] as int).withOpacity(0.7)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
              )),
              child: SafeArea(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(p['emoji'] as String, style: const TextStyle(fontSize: 100)),
                  const SizedBox(height: 40),
                  Text(p['title'] as String, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text(p['subtitle'] as String, style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w500)),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(p['body'] as String, textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.75), height: 1.5)),
                  ),
                ]),
              ),
            );
          },
        ),
        // Bottom controls
        Positioned(bottom: 48, left: 0, right: 0, child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(_pages.length, (i) =>
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _page == i ? 24 : 8, height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(_page == i ? 1 : 0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            )
          )),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: ElevatedButton(
              onPressed: () {
                if (_page < _pages.length - 1) {
                  _pageCtrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                } else {
                  context.go('/auth/role');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary),
              child: Text(_page == _pages.length - 1 ? 'सुरू करा (Get Started) 🚀' : 'पुढे →'),
            ),
          ),
        ])),
      ]),
    );
  }
}
