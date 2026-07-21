import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoId;
  final String title;
  final String channel;
  final String? thumbnailUrl;

  const VideoPlayerScreen({
    super.key,
    required this.videoId,
    required this.title,
    required this.channel,
    this.thumbnailUrl,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with SingleTickerProviderStateMixin {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _initController();
  }

  void _initController() {
    // ── Platform-specific params (fix Android video playback) ────────────────
    final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      params = AndroidWebViewControllerCreationParams();
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      // Spoof user-agent so YouTube allows embedding in WebView
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 12; Pixel 6) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/112.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          if (mounted) setState(() { _isLoading = true; _hasError = false; });
        },
        onPageFinished: (_) {
          if (mounted) {
            setState(() => _isLoading = false);
            _fadeCtrl.forward();
          }
        },
        onWebResourceError: (err) {
          // Only flag main frame errors; sub-resource errors are fine
          if (err.isForMainFrame ?? false) {
            if (mounted) setState(() { _isLoading = false; _hasError = true; });
          }
        },
        // Allow YouTube navigation within embed
        onNavigationRequest: (req) {
          if (req.url.contains('youtube.com') ||
              req.url.contains('youtu.be') ||
              req.url.contains('googlevideo.com')) {
            return NavigationDecision.navigate;
          }
          return NavigationDecision.prevent;
        },
      ))
      // KEY FIX: set baseUrl to youtube.com so the iframe is same-origin
      ..loadHtmlString(_buildEmbedHtml(widget.videoId),
          baseUrl: 'https://www.youtube.com');

    // ── Android: allow autoplay without user gesture ─────────────────────────
    if (_controller.platform is AndroidWebViewController) {
      (_controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }
  }

  String _buildEmbedHtml(String videoId) {
    return '''<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport"
        content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body {
      width: 100%; height: 100%;
      background: #000;
      overflow: hidden;
    }
    .wrap {
      position: relative;
      width: 100%;
      padding-top: 56.25%;  /* 16:9 */
    }
    iframe {
      position: absolute;
      inset: 0;
      width: 100%;
      height: 100%;
      border: none;
    }
  </style>
</head>
<body>
  <div class="wrap">
    <iframe
      id="ytplayer"
      src="https://www.youtube.com/embed/$videoId?autoplay=1&rel=0&showinfo=0&modestbranding=1&playsinline=1&controls=1&enablejsapi=1&origin=https://www.youtube.com"
      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
      allowfullscreen>
    </iframe>
  </div>
</body>
</html>''';
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _shareVideo() {
    Share.share(
      'Watch this farming video 🌾\n${widget.title}\nhttps://youtu.be/${widget.videoId}',
    );
  }

  void _retryLoad() {
    setState(() { _isLoading = true; _hasError = false; });
    _fadeCtrl.reset();
    _controller.loadHtmlString(
      _buildEmbedHtml(widget.videoId),
      baseUrl: 'https://www.youtube.com',
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final playerH = r.width * (9 / 16) + r.safePadding.top;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Column(
        children: [
          // ── Video Player ───────────────────────────────────────────────────
          SizedBox(
            height: playerH,
            child: Stack(
              children: [
                // WebView — shown when loaded
                Positioned.fill(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: WebViewWidget(controller: _controller),
                  ),
                ),

                // Loading overlay
                if (_isLoading && !_hasError)
                  Positioned.fill(
                    child: _LoadingOverlay(safePadding: r.safePadding.top),
                  ),

                // Error overlay
                if (_hasError)
                  Positioned.fill(
                    child: _ErrorOverlay(
                      onRetry: _retryLoad,
                      safePadding: r.safePadding.top,
                    ),
                  ),

                // Back button (always visible)
                Positioned(
                  top: r.safePadding.top + 8,
                  left: 8,
                  child: _CircleBtn(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),

                // Share button
                Positioned(
                  top: r.safePadding.top + 8,
                  right: 8,
                  child: _CircleBtn(
                    icon: Icons.share_rounded,
                    onTap: _shareVideo,
                  ),
                ),
              ],
            ),
          ),

          // ── Info Panel ────────────────────────────────────────────────────
          Expanded(
            child: Container(
              color: AppColors.background,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    r.rs(18), r.rs(18), r.rs(18), r.rs(24)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      widget.title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: r.sp(16.5),
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        height: r.rh(1.35),
                      ),
                    ),
                    SizedBox(height: r.rs(14)),

                    // Channel row
                    Row(
                      children: [
                        Container(
                          width: r.rs(38), height: r.rs(38),
                          decoration: BoxDecoration(
                            gradient: AppColors.farmerGradient,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text('🌾',
                                style: TextStyle(fontSize: r.sp(18))),
                          ),
                        ),
                        SizedBox(width: r.rs(10)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.channel,
                                style: GoogleFonts.inter(
                                  fontSize: r.sp(13.5),
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                              Text(
                                'YouTube Farming Channel',
                                style: GoogleFonts.inter(
                                    fontSize: r.sp(11),
                                    color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                        // YouTube badge
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: r.rs(12), vertical: r.rs(7)),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF0000).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(r.rs(20)),
                            border: Border.all(
                                color: const Color(0xFFFF0000)
                                    .withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.smart_display_rounded,
                                  color: Color(0xFFFF0000), size: 15),
                              SizedBox(width: r.rs(4)),
                              Text(
                                'YouTube',
                                style: GoogleFonts.inter(
                                  fontSize: r.sp(12),
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFFF0000),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: r.rs(18)),
                    Divider(color: AppColors.border, height: 1),
                    SizedBox(height: r.rs(14)),

                    // Action buttons
                    Row(
                      children: [
                        _InfoAction(
                          icon: Icons.share_rounded,
                          label: 'Share',
                          onTap: _shareVideo,
                        ),
                        SizedBox(width: r.rs(10)),
                        _InfoAction(
                          icon: Icons.thumb_up_alt_outlined,
                          label: 'Helpful',
                          onTap: () => HapticFeedback.lightImpact(),
                        ),
                        SizedBox(width: r.rs(10)),
                        _InfoAction(
                          icon: Icons.replay_rounded,
                          label: 'Reload',
                          onTap: _retryLoad,
                        ),
                      ],
                    ),

                    SizedBox(height: r.rs(20)),

                    // Tip card
                    Container(
                      padding: EdgeInsets.all(r.rs(14)),
                      decoration: BoxDecoration(
                        color: AppColors.farmerTint,
                        borderRadius: BorderRadius.circular(r.rs(14)),
                        border: Border.all(
                            color: AppColors.farmerAccent.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('💡', style: TextStyle(fontSize: r.sp(20))),
                          SizedBox(width: r.rs(10)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Farmer's Tip",
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: r.sp(13),
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.farmerAccent,
                                  ),
                                ),
                                SizedBox(height: r.rs(3)),
                                Text(
                                  'If the video doesn\'t play, tap the Reload button above. '
                                  'Visit Kisan AI for personalized advice on what you learned.',
                                  style: GoogleFonts.inter(
                                    fontSize: r.sp(12),
                                    color: AppColors.ink,
                                    height: r.rh(1.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Overlays ──────────────────────────────────────────────────────────────────

class _LoadingOverlay extends StatelessWidget {
  final double safePadding;
  const _LoadingOverlay({required this.safePadding});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Container(
      color: Colors.black,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: safePadding),
          SizedBox(width: r.rs(36), height: r.rh(36),
            child: CircularProgressIndicator(
              color: Colors.red, strokeWidth: r.rs(2.5),
            ),
          ),
          SizedBox(height: r.rh(16)),
          Text(
            'Loading video...',
            style: GoogleFonts.inter(color: Colors.white60, fontSize: r.sp(13)),
          ),
        ],
      ),
    );
  }
}

class _ErrorOverlay extends StatelessWidget {
  final VoidCallback onRetry;
  final double safePadding;
  const _ErrorOverlay({required this.onRetry, required this.safePadding});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Container(
      color: Colors.black,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: safePadding),
          Text('📡', style: TextStyle(fontSize: r.sp(36))),
          SizedBox(height: r.rh(12)),
          Text(
            'Video failed to load',
            style: GoogleFonts.spaceGrotesk(
                color: Colors.white, fontSize: r.sp(14), fontWeight: FontWeight.w700),
          ),
          SizedBox(height: r.rh(4)),
          Text(
            'Check your internet connection',
            style: GoogleFonts.inter(color: Colors.white54, fontSize: r.sp(12)),
          ),
          SizedBox(height: r.rh(16)),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: r.rs(20), vertical: r.rh(9)),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(r.rs(20)),
              ),
              child: Text('Try Again',
                  style: GoogleFonts.inter(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: r.rs(40), height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Icon(icon, color: Colors.white, size: r.sp(20)),
      ),
    );
  }
}

class _InfoAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _InfoAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: r.rs(13), vertical: r.rs(9)),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(r.rs(22)),
          border: Border.all(color: AppColors.border),
          boxShadow: AppColors.softShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: r.rs(15), color: AppColors.farmerAccent),
            SizedBox(width: r.rs(5)),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: r.sp(12.5),
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
