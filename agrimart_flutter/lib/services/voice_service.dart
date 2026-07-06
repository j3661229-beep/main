import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  static final VoiceService instance = VoiceService._();
  VoiceService._();

  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();

  bool _isTtsInitialized = false;
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;
  bool get isListening => _stt.isListening;

  Future<void> init() async {
    if (_isTtsInitialized) return;
    await _tts.setLanguage('en-IN');
    await _tts.setSpeechRate(0.48);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _tts.setCompletionHandler(() => _isSpeaking = false);
    _tts.setCancelHandler(() => _isSpeaking = false);
    _isTtsInitialized = true;
  }

  Future<void> speak(String text, {String? languageCode}) async {
    if (text.trim().isEmpty) return;
    await init();
    await stop();

    String code = 'en-IN';
    final lang = languageCode?.toLowerCase() ?? '';
    if (lang.contains('marathi') || lang == 'mr') {
      code = 'mr-IN';
    } else if (lang.contains('hindi') || lang == 'hi') {
      code = 'hi-IN';
    }

    _isSpeaking = true;
    await _tts.setLanguage(code);
    await _tts.speak(text);
  }

  Future<void> stop() async {
    _isSpeaking = false;
    await _tts.stop();
  }

  Future<bool> initSpeech() async {
    return _stt.initialize();
  }

  Future<void> startListening(Function(String) onResult, {String? localeId}) async {
    if (!_stt.isAvailable) await initSpeech();
    await _stt.listen(
      onResult: (result) => onResult(result.recognizedWords),
      localeId: localeId ?? 'en-IN',
      listenMode: ListenMode.confirmation,
    );
  }

  Future<void> stopListening() async {
    await _stt.stop();
  }
}
