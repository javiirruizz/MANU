import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();

  AudioService() {
    _tts.setLanguage("es-ES"); // Español por defecto
    _tts.setSpeechRate(0.4);   // Velocidad un poco más lenta para mejor accesibilidad
  }

  Future<void> leerTexto(String texto) async {
    await _audioPlayer.stop(); // Detiene cualquier audio previo
    await _tts.speak(texto);
  }

  Future<void> reproducirAudio(String url) async {
    await _tts.stop(); // Detiene la voz robótica si estaba hablando
    await _audioPlayer.play(UrlSource(url));
  }

  Future<void> detenerTodo() async {
    await _tts.stop();
    await _audioPlayer.stop();
  }
}