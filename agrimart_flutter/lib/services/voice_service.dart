import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'dart:async';

class VoiceService {
  static final VoiceService instance = VoiceService._();
  VoiceService._();

  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();

  bool _isTtsInitialized = false;

  Future<void> init() async {
    if (_isTtsInitialized) return;
    await _tts.setLanguage("en-IN");
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _isTtsInitialized = true;
  }

  Future<void> speak(String text, {String? languageCode}) async {
    await init();
    // Map App Language to TTS codes
    String code = "en-IN";
    if (languageCode?.contains("Marathi") == true) code = "mr-IN";
    if (languageCode?.contains("Hindi") == true) code = "hi-IN";
    
    await _tts.setLanguage(code);
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  Future<bool> initSpeech() async {
    return await _stt.initialize();
  }

  Future<void> startListening(Function(String) onResult) async {
    if (!_stt.isAvailable) await initSpeech();
    await _stt.listen(
      onResult: (result) => onResult(result.recognizedWords),
      localeId: "en-IN", // Can be dynamic based on settings
    );
  }

  Future<void> stopListening() async {
    await _stt.stop();
  }

  bool get isListening => _stt.isListening;
}
