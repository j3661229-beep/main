import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class KisanAiScreen extends ConsumerStatefulWidget {
  const KisanAiScreen({super.key});
  @override
  ConsumerState<KisanAiScreen> createState() => _KisanAiScreenState();
}

class _KisanAiScreenState extends ConsumerState<KisanAiScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('kisan_chat_history');
    if (data != null) {
      final List decoded = jsonDecode(data);
      if (mounted) {
        setState(() {
          _messages.clear();
          for (var item in decoded) {
            _messages.add(Map<String, String>.from(item));
          }
        });
        _scrollToBottom();
      }
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('kisan_chat_history', jsonEncode(_messages));
  }

  final _suggestions = [
    'माझ्या कांद्याची पाने पिवळ्या होत आहेत, काय करू?',
    'सोयाबीनसाठी कोणते खत वापरावे?',
    'What fertilizer is best for onion crop?',
    'मला आंबा बागेसाठी सल्ला द्या',
  ];

  Future<void> _send(String msg) async {
    if (msg.trim().isEmpty) return;
    _ctrl.clear();
    setState(() { _messages.add({'role': 'user', 'content': msg}); _loading = true; });
    await _saveHistory();
    _scrollToBottom();
    try {
      final history = _messages.map((m) => {'role': m['role']!, 'content': m['content']!}).toList();
      final res = await ApiService.instance.kisanChat(message: msg, history: history.length > 1 ? history.sublist(0, history.length - 1) : []);
      if (mounted) setState(() { _messages.add({'role': 'assistant', 'content': res['reply'] ?? 'I could not answer that.'}); _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _messages.add({'role': 'assistant', 'content': 'Sorry, I had trouble connecting. Please try again.'}); _loading = false; });
    }
    await _saveHistory();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Row(children: [
          Text('🤖', style: TextStyle(fontSize: 22)),
          SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Kisan AI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            Text('मराठी | हिंदी | English', style: TextStyle(fontSize: 11, color: Colors.white70)),
          ]),
        ]),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              tooltip: 'Clear History',
              onPressed: () async {
                setState(() => _messages.clear());
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('kisan_chat_history');
              },
            ),
        ],
      ),
      body: Column(children: [
        // Welcome / suggestions
        if (_messages.isEmpty) Expanded(child: ListView(padding: const EdgeInsets.all(20), children: [
          const Center(child: Text('🤖', style: TextStyle(fontSize: 64))),
          const SizedBox(height: 12),
          const Text('Kisan AI Assistant', style: AppTextStyles.headingXL, textAlign: TextAlign.center),
          const Text('Ask any farming question in Marathi, Hindi or English', style: AppTextStyles.bodySM, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          const Text('Quick Questions:', style: AppTextStyles.headingSM),
          const SizedBox(height: 12),
          ..._suggestions.map((s) => GestureDetector(
            onTap: () => _send(s),
            child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primaryBorder)),
              child: Text(s, style: AppTextStyles.bodyMD)),
          )),
        ]))
        else Expanded(child: ListView.builder(
          controller: _scrollCtrl,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          itemCount: _messages.length + (_loading ? 1 : 0),
          itemBuilder: (ctx, i) {
            if (i == _messages.length) return const Padding(padding: EdgeInsets.all(12), child: Row(children: [SizedBox(width: 20), Text('🤖 '), _TypingDots()]));
            final m = _messages[i];
            final isUser = m['role'] == 'user';
            return Align(
              alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                decoration: BoxDecoration(
                  color: isUser ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isUser ? 16 : 4), bottomRight: Radius.circular(isUser ? 4 : 16),
                  ),
                  border: isUser ? null : Border.all(color: AppColors.border),
                ),
                child: Text(m['content']!, style: AppTextStyles.bodyMD.copyWith(color: isUser ? Colors.white : AppColors.textPrimary)),
              ),
            );
          },
        )),

        // Input bar
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          decoration: BoxDecoration(color: AppColors.surface, border: const Border(top: BorderSide(color: AppColors.border))),
          child: SafeArea(child: Row(children: [
            Expanded(child: TextField(
              controller: _ctrl,
              decoration: const InputDecoration(hintText: 'Ask anything in Marathi, Hindi or English…', border: InputBorder.none, filled: false),
              maxLines: null,
              onSubmitted: _send,
            )),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _send(_ctrl.text),
              child: Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20)),
            ),
          ])),
        ),
      ]),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}
class _TypingDotsState extends State<_TypingDots> with TickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Row(children: List.generate(3, (i) =>
    AnimatedBuilder(animation: _c, builder: (ctx, _) => Container(margin: const EdgeInsets.only(right: 3), width: 6, height: 6, decoration: BoxDecoration(color: AppColors.primary.withOpacity(_c.value), shape: BoxShape.circle)))));
}
