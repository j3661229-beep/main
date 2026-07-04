import 'package:flutter/material.dart';
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
    ErrorWidget.builder = (FlutterErrorDetails details) {
      if (mounted) setState(() => _error = details.exception);
      FlutterError.presentError(details);
      return const SizedBox.shrink();
    };
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
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Color(0xFFFDE8E8), Colors.white],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 80, color: Color(0xFFE02424)),
                const SizedBox(height: 24),
                Text('काहीतरी चुकले आहे!',
                  style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937)),
                  textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text('कृपया ॲप पुन्हा सुरू करा.',
                  style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF4B5563)),
                  textAlign: TextAlign.center),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => setState(() => _error = null),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE02424), foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('पुन्हा प्रयत्न करा'),
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

/// Global error handler — call from main() before runApp
void setUpErrorHandling() {
  FlutterError.onError = FlutterError.presentError;
}
