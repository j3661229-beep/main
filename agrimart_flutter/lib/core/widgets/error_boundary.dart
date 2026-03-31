import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:google_fonts/google_fonts.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  const ErrorBoundary({super.key, required this.child});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;

  @override
  void initState() {
    super.initState();
  }

  void _handleError(Object error, StackTrace stackTrace) {
    setState(() {
      _error = error;
    });
    FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFDE8E8), Colors.white],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 80, color: Color(0xFFE02424)),
                const SizedBox(height: 24),
                Text(
                  'Kahi tari chukle aahe!', // Something went wrong (Marathi)
                  style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Aamhi hyala durusta karneyacha prayatna karat aahot. Kripaya app punha chalu kara.',
                  style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF4B5563)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    // Force restart conceptually or just clear error state for now
                    setState(() { _error = null; });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE02424),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Restart App'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}

// Global error handler utility
void setUpErrorHandling() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    FirebaseCrashlytics.instance.recordFlutterError(details);
  };
}
