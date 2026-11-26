import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  FlutterTts? _tts;
  AudioPlayer? _audioPlayer;
  AudioPlayer? _completed;

  Future<FlutterTts> _getTts() async {
    if (_tts == null) {
      final tts = FlutterTts();
      await tts.setLanguage('es-ES'); // Español por defecto
      await tts.setSpeechRate(
        0.4,
      ); // Velocidad un poco más lenta para mejor accesibilidad
      _tts = tts;
    }
    return _tts!;
  }

  AudioPlayer _getAudioPlayer() => _audioPlayer ??= AudioPlayer();

  AudioPlayer _getCompletedPlayer() => _completed ??= AudioPlayer();

  Future<void> leerTexto(String texto) async {
    await _audioPlayer?.stop(); // Detiene cualquier audio previo
    final tts = await _getTts();
    await tts.speak(texto);
  }

  Future<void> reproducirAudio(String url) async {
    await _tts?.stop(); // Detiene la voz robótica si estaba hablando
    await _getAudioPlayer().play(UrlSource(url));
  }

  Future<void> detenerTodo() async {
    await _tts?.stop();
    await _audioPlayer?.stop();
  }

  Future<void> reproducirExito() async {
    final player = _getCompletedPlayer();
    await player.stop();
    await player.play(AssetSource('audio/exito.mp3'));
  }
}
