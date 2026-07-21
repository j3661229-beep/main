import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../data/services/api_service.dart';
import '../../data/providers/auth_provider.dart';
import '../../core/providers/app_language_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/utils/farm_profile_utils.dart';
import '../../services/voice_service.dart';
import 'package:agrimart/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/ai_analysis_progress.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/utils/responsive.dart';

class KisanAiScreen extends ConsumerStatefulWidget {
  final bool embedded;
  final bool isActive;
  const KisanAiScreen({super.key, this.embedded = false, this.isActive = true});

  @override
  ConsumerState<KisanAiScreen> createState() => _KisanAiScreenState();
}

class _KisanAiScreenState extends ConsumerState<KisanAiScreen> with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();
  final List<Map<String, String>> _messages = [];
  bool _loading = false;
  bool _isListening = false;
  String? _currentlySpeakingId;
  late final AnimationController _pulseCtrl;

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    if (widget.isActive) _activate();
  }

  @override
  void didUpdateWidget(KisanAiScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) _activate();
    if (!widget.isActive && oldWidget.isActive) _pulseCtrl.stop();
  }

  void _activate() {
    if (_initialized) {
      if (!_pulseCtrl.isAnimating) _pulseCtrl.repeat(reverse: true);
      return;
    }
    _initialized = true;
    _pulseCtrl.repeat(reverse: true);
    _loadHistory();
  }

  @override
  void dispose() {
    ApiService.instance.cancelAiRequest();
    _pulseCtrl.dispose();
    VoiceService.instance.stop();
    VoiceService.instance.stopListening();
    _ctrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _t(String en, String hi, String mr) {
    final code = ref.read(localeProvider).languageCode;
    if (code == 'hi') return hi;
    if (code == 'mr') return mr;
    return en;
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('kisan_chat_history');
    if (data != null) {
      final decoded = jsonDecode(data) as List;
      if (mounted) {
        setState(() {
          _messages
            ..clear()
            ..addAll(decoded.map((e) => Map<String, String>.from(e as Map)));
        });
        _scrollToBottom();
      }
    }
  }

  Future<void> _saveHistory() async {
    const maxMessages = 50;
    final toSave = _messages.length > maxMessages
        ? _messages.sublist(_messages.length - maxMessages)
        : _messages;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('kisan_chat_history', jsonEncode(toSave));
  }

  Future<void> _clearChat() async {
    setState(() => _messages.clear());
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('kisan_chat_history');
  }

  List<_PromptCategory> _categories(AppLocalizations l10n) => [
        _PromptCategory(
          emoji: '🌦️',
          label: _t('Weather', 'मौसम', 'हवामान'),
          prompts: [
            _t('Will it rain in my village this week?', 'इस हफ्ते मेरे गाँव में बारिश होगी?', 'या आठवड्यात माझ्या गावात पाऊस येईल का?'),
            _t('What should I do before heavy rain?', 'भारी बारिश से पहले क्या करूं?', 'जोरदार पाऊस आधी काय करावे?'),
          ],
        ),
        _PromptCategory(
          emoji: '🌾',
          label: _t('Crops', 'फसल', 'पिके'),
          prompts: [
            l10n.kisanPromptSpray,
            _t('Best fertilizer dose for 2 acre onion?', '2 एकड़ प्याज के लिए खाद?', '2 एकर कांद्यासाठी खत?'),
          ],
        ),
        _PromptCategory(
          emoji: '💰',
          label: _t('Mandi', 'मंडी', 'मंडी'),
          prompts: [
            l10n.kisanPromptMandi,
            _t('When is best time to sell soybean?', 'सोयाबीन बेचने का सही समय?', 'सोयाबीन विकण्याची वेळ?'),
          ],
        ),
        _PromptCategory(
          emoji: '🏛️',
          label: _t('Schemes', 'योजना', 'योजना'),
          prompts: [
            l10n.kisanPromptPmfby,
            _t('How to apply PM-Kisan?', 'PM-Kisan कैसे लें?', 'PM-Kisan कसा मिळवायचा?'),
          ],
        ),
      ];

  Future<void> _send(String msg) async {
    if (msg.trim().isEmpty || _loading) return;
    _ctrl.clear();
    _focusNode.unfocus();
    final langName = ref.read(appLanguageProvider).aiName;

    setState(() {
      _messages.add({
        'role': 'user',
        'content': msg.trim(),
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      });
      _loading = true;
    });
    await _saveHistory();
    _scrollToBottom();

    try {
      final history = _messages.map((m) => {'role': m['role']!, 'content': m['content']!}).toList();
      final res = await ApiService.instance.kisanChat(
        message: msg.trim(),
        history: history.length > 1 ? history.sublist(0, history.length - 1) : [],
        language: langName,
      );
      if (!mounted) return;
      final reply = res['reply']?.toString() ?? _t('Could not answer. Try again.', 'जवाब नहीं मिला।', 'उत्तर मिळाले नाही.');
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      setState(() {
        _messages.add({'role': 'assistant', 'content': reply, 'id': id});
        _loading = false;
      });
      _speak(reply, id);
    } catch (e) {
      if (!mounted) return;
      if (isRequestCancelled(e)) {
        setState(() => _loading = false);
        return;
      }
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': _t(
            'Connection issue. Check internet and try again.',
            'इंटरनेट जांचें और फिर कोशिश करें।',
            'इंटरनेट तपासा आणि पुन्हा प्रयत्न करा.',
          ),
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
        });
        _loading = false;
      });
    }
    await _saveHistory();
    _scrollToBottom();
  }

  void _cancelReply() {
    ApiService.instance.cancelAiRequest();
    if (mounted) setState(() => _loading = false);
  }

  void _speak(String text, String id) async {
    final locale = ref.read(localeProvider);
    setState(() => _currentlySpeakingId = id);
    await VoiceService.instance.speak(text, languageCode: locale.languageCode);
    if (mounted) setState(() => _currentlySpeakingId = null);
  }

  void _stopSpeak() async {
    await VoiceService.instance.stop();
    if (mounted) setState(() => _currentlySpeakingId = null);
  }

  Future<void> _toggleListen() async {
    if (_isListening) {
      await VoiceService.instance.stopListening();
      setState(() => _isListening = false);
    } else {
      final available = await VoiceService.instance.initSpeech();
      if (!available) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_t('Microphone not available', 'माइक उपलब्ध नहीं', 'मायक उपलब्ध नाही'))),
          );
        }
        return;
      }
      setState(() => _isListening = true);
      await VoiceService.instance.startListening((text) {
        if (mounted) _ctrl.text = text;
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_t('Copied', 'कॉपी हो गया', 'कॉपी झाले')),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authProvider).user;
    final farmer = user?.farmer;
    final district = user?.effectiveDistrict ?? 'Maharashtra';
    final crops = FarmProfileUtils.cropsDisplay(farmer);
    final langLabel = ref.watch(appLanguageProvider).code == 'hi'
        ? 'हिंदी'
        : ref.watch(appLanguageProvider).code == 'mr'
            ? 'मराठी'
            : 'English';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F0),
      body: Column(
        children: [
          _KisanHeader(
            embedded: widget.embedded,
            langLabel: langLabel,
            onlineLabel: _t('Online', 'ऑनलाइन', 'ऑनलाइन'),
            title: l10n.kisanAi,
            district: district,
            crops: crops,
            isSpeaking: _currentlySpeakingId != null,
            hasMessages: _messages.isNotEmpty,
            onBack: () => Navigator.of(context).maybePop(),
            onStopSpeak: _stopSpeak,
            onClear: _messages.isEmpty
                ? null
                : () => showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(_t('Clear chat?', 'चैट मिटाएं?', 'चॅट साफ करायची?')),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _clearChat();
                            },
                            child: Text(_t('Clear', 'मिटाएं', 'साफ करा'), style: const TextStyle(color: AppColors.danger)),
                          ),
                        ],
                      ),
                    ),
          ),
          Expanded(
            child: _messages.isEmpty
                ? _EmptyState(
                    categories: _categories(l10n),
                    onPrompt: _send,
                    welcomeTitle: _t('Namaste! I am Kisan AI', 'नमस्ते! मैं किसान AI हूँ', 'नमस्कार! मी किसान AI'),
                    welcomeSub: _t(
                      'Ask anything about crops, weather, mandi & schemes',
                      'फसल, मौसम, मंडी और योजनाओं के बारे में पूछें',
                      'पिके, हवामान, मंडी व योजनांबद्दल विचारा',
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: EdgeInsets.fromLTRB(r.horizontalPadding, r.rs(12), r.horizontalPadding, r.rs(8)),
                    itemCount: _messages.length + (_loading ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i == _messages.length) {
                        return FadeInUp(
                          duration: const Duration(milliseconds: 300),
                          child: AiAnalyzingBubble(
                            label: _t('Analyzing…', 'विश्लेषण…', 'विश्लेषण…'),
                            cancelLabel: l10n.cancel,
                            onCancel: _cancelReply,
                          ),
                        );
                      }
                      final m = _messages[i];
                      final isUser = m['role'] == 'user';
                      return FadeInUp(
                        duration: Duration(milliseconds: 280 + (i % 3) * 40),
                        child: _MessageBubble(
                          text: m['content']!,
                          isUser: isUser,
                          isSpeaking: _currentlySpeakingId == m['id'],
                          onSpeak: isUser ? null : () => _currentlySpeakingId == m['id'] ? _stopSpeak() : _speak(m['content']!, m['id']!),
                          onCopy: isUser ? null : () => _copyMessage(m['content']!),
                        ),
                      );
                    },
                  ),
          ),
          if (_messages.isNotEmpty && !_loading)
            _QuickReplyStrip(
              prompts: [
                _t('Tell me more', 'और बताएं', 'अजून सांगा'),
                _t('In simple words', 'आसान भाषा में', 'सोप्या भाषेत'),
                l10n.kisanPromptMandi,
              ],
              onTap: _send,
            ),
          _InputBar(
            controller: _ctrl,
            focusNode: _focusNode,
            isListening: _isListening,
            isLoading: _loading,
            pulseAnimation: _pulseCtrl,
            hint: _t('Ask in $langLabel…', '$langLabel में पूछें…', '$langLabel मध्ये विचारा…'),
            onListen: _toggleListen,
            onSend: () => _send(_ctrl.text),
          ),
        ],
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _KisanHeader extends StatelessWidget {
  final bool embedded;
  final String title;
  final String langLabel;
  final String onlineLabel;
  final String district;
  final String crops;
  final bool isSpeaking;
  final bool hasMessages;
  final VoidCallback onBack;
  final VoidCallback? onStopSpeak;
  final VoidCallback? onClear;

  const _KisanHeader({
    required this.embedded,
    required this.title,
    required this.langLabel,
    required this.onlineLabel,
    required this.district,
    required this.crops,
    required this.isSpeaking,
    required this.hasMessages,
    required this.onBack,
    this.onStopSpeak,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.farmerAccent,
            AppColors.farmerAccent.withValues(alpha: 0.85),
            const Color(0xFF3D6B35),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.farmerAccent.withValues(alpha: 0.35),
            blurRadius: r.rs(20),
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(r.rs(8), r.rs(4), r.rs(12), r.rs(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (!embedded)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: onBack,
                    ),
                  _AiAvatar(size: r.rs(48)),
                  SizedBox(width: r.rs(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: GoogleFonts.spaceGrotesk(fontSize: r.sp(20), fontWeight: FontWeight.w800, color: Colors.white)),
                        Row(
                          children: [
                            Container(
                              width: r.rs(8),
                              height: r.rh(8),
                              decoration: const BoxDecoration(color: Color(0xFF86EFAC), shape: BoxShape.circle),
                            ),
                            SizedBox(width: r.rs(6)),
                            Text(
                              '$onlineLabel · $langLabel',
                              style: GoogleFonts.inter(fontSize: r.sp(12), color: Colors.white.withValues(alpha: 0.85)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isSpeaking)
                    IconButton(
                      icon: const Icon(Icons.stop_circle_rounded, color: Colors.white),
                      onPressed: onStopSpeak,
                    ),
                  if (hasMessages)
                    IconButton(
                      icon: Icon(Icons.delete_sweep_outlined, color: Colors.white.withValues(alpha: 0.9)),
                      onPressed: onClear,
                    ),
                ],
              ),
              if (district.isNotEmpty || crops != '—') ...[
                SizedBox(height: r.rs(12)),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (district.isNotEmpty)
                        _ContextChip(icon: Icons.location_on_rounded, label: district),
                      if (crops != '—') ...[
                        SizedBox(width: r.rs(8)),
                        _ContextChip(icon: Icons.grass_rounded, label: crops),
                      ],
                      SizedBox(width: r.rs(8)),
                      _ContextChip(icon: Icons.auto_awesome_rounded, label: 'AI Powered'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ContextChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ContextChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: r.rs(12), vertical: r.rh(6)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(r.rs(20)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: r.sp(14), color: Colors.white.withValues(alpha: 0.95)),
          SizedBox(width: r.rs(6)),
          Text(label, style: GoogleFonts.inter(fontSize: r.sp(11), fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }
}

class _AiAvatar extends StatelessWidget {
  final double size;
  const _AiAvatar({required this.size});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: r.rs(12), offset: Offset(0, 4)),
        ],
      ),
      child: Center(child: Text('🌾', style: TextStyle(fontSize: size * 0.48))),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _PromptCategory {
  final String emoji;
  final String label;
  final List<String> prompts;
  const _PromptCategory({required this.emoji, required this.label, required this.prompts});
}

class _EmptyState extends StatefulWidget {
  final List<_PromptCategory> categories;
  final ValueChanged<String> onPrompt;
  final String welcomeTitle;
  final String welcomeSub;

  const _EmptyState({
    required this.categories,
    required this.onPrompt,
    required this.welcomeTitle,
    required this.welcomeSub,
  });

  @override
  State<_EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<_EmptyState> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final cat = widget.categories[_selected];

    return ListView(
      padding: EdgeInsets.fromLTRB(r.horizontalPadding, r.rs(20), r.horizontalPadding, r.rs(16)),
      children: [
        FadeInDown(
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: r.rs(120),
                    height: r.rs(120),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.farmerAccent.withValues(alpha: 0.08),
                    ),
                  ),
                  Container(
                    width: r.rs(88),
                    height: r.rs(88),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.farmerGradient,
                      boxShadow: [
                        BoxShadow(color: AppColors.farmerAccent.withValues(alpha: 0.35), blurRadius: r.rs(24), offset: Offset(0, 8)),
                      ],
                    ),
                    child: Center(child: Text('🤖', style: TextStyle(fontSize: r.sp(44)))),
                  ),
                ],
              ),
              SizedBox(height: r.rs(20)),
              Text(
                widget.welcomeTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(fontSize: r.sp(22), fontWeight: FontWeight.w800, color: AppColors.ink),
              ),
              SizedBox(height: r.rs(8)),
              Text(
                widget.welcomeSub,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: r.sp(14), color: AppColors.muted, height: 1.5),
              ),
            ],
          ),
        ),
        SizedBox(height: r.rs(28)),
        SizedBox(
          height: r.rs(44),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.categories.length,
            separatorBuilder: (_, __) => SizedBox(width: r.rs(8)),
            itemBuilder: (ctx, i) {
              final c = widget.categories[i];
              final sel = i == _selected;
              return GestureDetector(
                onTap: () => setState(() => _selected = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(horizontal: r.rs(16), vertical: r.rs(10)),
                  decoration: BoxDecoration(
                    gradient: sel ? AppColors.farmerGradient : null,
                    color: sel ? null : Colors.white,
                    borderRadius: BorderRadius.circular(r.rs(22)),
                    border: Border.all(color: sel ? Colors.transparent : AppColors.border),
                    boxShadow: sel ? [BoxShadow(color: AppColors.farmerAccent.withValues(alpha: 0.25), blurRadius: r.rs(8), offset: Offset(0, 3))] : AppColors.softShadow,
                  ),
                  child: Row(
                    children: [
                      Text(c.emoji, style: TextStyle(fontSize: r.sp(16))),
                      SizedBox(width: r.rs(6)),
                      Text(
                        c.label,
                        style: GoogleFonts.inter(
                          fontSize: r.sp(13),
                          fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: r.rs(16)),
        ...cat.prompts.asMap().entries.map((e) => FadeInUp(
              delay: Duration(milliseconds: 80 * e.key),
              child: _PromptCard(text: e.value, emoji: cat.emoji, onTap: () => widget.onPrompt(e.value)),
            )),
      ],
    );
  }
}

class _PromptCard extends StatelessWidget {
  final String text;
  final String emoji;
  final VoidCallback onTap;

  const _PromptCard({required this.text, required this.emoji, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Padding(
      padding: EdgeInsets.only(bottom: r.rs(10)),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r.rs(18)),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(r.rs(18)),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(r.rs(16)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(r.rs(18)),
              border: Border.all(color: AppColors.farmerAccent.withValues(alpha: 0.15)),
              boxShadow: AppColors.softShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: r.rs(40),
                  height: r.rs(40),
                  decoration: BoxDecoration(
                    color: AppColors.farmerTint,
                    borderRadius: BorderRadius.circular(r.rs(12)),
                  ),
                  child: Center(child: Text(emoji, style: TextStyle(fontSize: r.sp(20)))),
                ),
                SizedBox(width: r.rs(12)),
                Expanded(
                  child: Text(text, style: GoogleFonts.inter(fontSize: r.sp(14), color: AppColors.ink, height: 1.4)),
                ),
                Icon(Icons.north_east_rounded, size: r.rs(18), color: AppColors.farmerAccent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Messages ─────────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool isSpeaking;
  final VoidCallback? onSpeak;
  final VoidCallback? onCopy;

  const _MessageBubble({
    required this.text,
    required this.isUser,
    this.isSpeaking = false,
    this.onSpeak,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Padding(
      padding: EdgeInsets.only(bottom: r.rs(14)),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            _AiAvatar(size: r.rs(34)),
            SizedBox(width: r.rs(8)),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: r.rs(16), vertical: r.rs(12)),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? LinearGradient(
                            colors: [AppColors.farmerAccent, AppColors.farmerAccent.withValues(alpha: 0.88)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isUser ? null : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(r.rs(20)),
                      topRight: Radius.circular(r.rs(20)),
                      bottomLeft: Radius.circular(isUser ? r.rs(20) : r.rs(6)),
                      bottomRight: Radius.circular(isUser ? r.rs(6) : r.rs(20)),
                    ),
                    border: isUser ? null : Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                    boxShadow: [
                      BoxShadow(
                        color: (isUser ? AppColors.farmerAccent : Colors.black).withValues(alpha: 0.08),
                        blurRadius: r.rs(12),
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    text,
                    style: GoogleFonts.inter(
                      fontSize: r.sp(15),
                      height: r.rh(1.55),
                      fontWeight: FontWeight.w500,
                      color: isUser ? Colors.white : AppColors.ink,
                    ),
                  ),
                ),
                if (!isUser && (onSpeak != null || onCopy != null))
                  Padding(
                    padding: EdgeInsets.only(top: r.rs(4), left: r.rs(4)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onSpeak != null)
                          _BubbleAction(
                            icon: isSpeaking ? Icons.stop_circle_outlined : Icons.volume_up_rounded,
                            label: isSpeaking ? 'Stop' : 'Listen',
                            color: isSpeaking ? AppColors.danger : AppColors.farmerAccent,
                            onTap: onSpeak!,
                          ),
                        if (onCopy != null) ...[
                          SizedBox(width: r.rs(8)),
                          _BubbleAction(icon: Icons.copy_rounded, label: 'Copy', onTap: onCopy!),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BubbleAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _BubbleAction({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return InkWell(
      borderRadius: BorderRadius.circular(r.rs(8)),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: r.rs(6), vertical: r.rh(4)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: r.sp(14), color: color ?? AppColors.muted),
            SizedBox(width: r.rs(4)),
            Text(label, style: GoogleFonts.inter(fontSize: r.sp(11), color: color ?? AppColors.muted, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ── Quick replies & input ────────────────────────────────────────────────────

class _QuickReplyStrip extends StatelessWidget {
  final List<String> prompts;
  final ValueChanged<String> onTap;

  const _QuickReplyStrip({required this.prompts, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return SizedBox(height: r.rh(40),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: r.rs(12)),
        itemCount: prompts.length,
        separatorBuilder: (_, __) => SizedBox(width: r.rs(8)),
        itemBuilder: (ctx, i) {
          return ActionChip(
            label: Text(prompts[i], style: GoogleFonts.inter(fontSize: r.sp(12))),
            backgroundColor: Colors.white,
            side: BorderSide(color: AppColors.farmerAccent.withValues(alpha: 0.3)),
            onPressed: () => onTap(prompts[i]),
          );
        },
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isListening;
  final bool isLoading;
  final AnimationController pulseAnimation;
  final String hint;
  final VoidCallback onListen;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.isListening,
    required this.isLoading,
    required this.pulseAnimation,
    required this.hint,
    required this.onListen,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Container(
      padding: EdgeInsets.fromLTRB(r.rs(12), r.rs(10), r.rs(12), r.rs(6)),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: r.rs(16), offset: Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: BoxConstraints(minHeight: r.rs(48), maxHeight: r.rs(120)),
                padding: EdgeInsets.symmetric(horizontal: r.rs(16)),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F7F0),
                  borderRadius: BorderRadius.circular(r.rs(24)),
                  border: Border.all(
                    color: isListening ? AppColors.danger.withValues(alpha: 0.5) : AppColors.border,
                    width: isListening ? 2 : 1,
                  ),
                ),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: GoogleFonts.inter(fontSize: r.sp(14), color: AppColors.placeholder),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: r.rs(14)),
                  ),
                  style: GoogleFonts.inter(fontSize: r.sp(15), color: AppColors.ink),
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                ),
              ),
            ),
            SizedBox(width: r.rs(8)),
            AnimatedBuilder(
              animation: pulseAnimation,
              builder: (_, child) {
                final scale = isListening ? 1.0 + pulseAnimation.value * 0.08 : 1.0;
                return Transform.scale(scale: scale, child: child);
              },
              child: _CircleBtn(
                icon: isListening ? Icons.stop_rounded : Icons.mic_rounded,
                color: isListening ? AppColors.danger : AppColors.farmerTint,
                iconColor: isListening ? Colors.white : AppColors.farmerAccent,
                onTap: isLoading ? null : onListen,
              ),
            ),
            SizedBox(width: r.rs(8)),
            _CircleBtn(
              icon: Icons.send_rounded,
              color: AppColors.farmerAccent,
              iconColor: Colors.white,
              onTap: isLoading ? null : onSend,
              shadow: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback? onTap;
  final bool shadow;

  const _CircleBtn({
    required this.icon,
    required this.color,
    required this.iconColor,
    this.onTap,
    this.shadow = false,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(r.rs(16)),
      elevation: shadow ? 4 : 0,
      shadowColor: AppColors.farmerAccent.withValues(alpha: 0.4),
      child: InkWell(
        borderRadius: BorderRadius.circular(r.rs(16)),
        onTap: onTap,
        child: SizedBox(
          width: r.rs(48),
          height: r.rs(48),
          child: Icon(icon, color: iconColor, size: r.rs(22)),
        ),
      ),
    );
  }
}
