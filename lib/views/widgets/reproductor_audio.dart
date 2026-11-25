import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class ReproductorAudioWidget extends StatefulWidget {
  final String url;

  const ReproductorAudioWidget({super.key, required this.url});

  @override
  State<ReproductorAudioWidget> createState() => _ReproductorAudioWidgetState();
}

class _ReproductorAudioWidgetState extends State<ReproductorAudioWidget> {
  final AudioPlayer _player = AudioPlayer();
  PlayerState _estado = PlayerState.stopped;
  Duration _duracion = Duration.zero;
  Duration _posicion = Duration.zero;

  late final StreamSubscription _stateSub;
  late final StreamSubscription _durationSub;
  late final StreamSubscription _positionSub;

  @override
  void initState() {
    super.initState();

    _stateSub = _player.onPlayerStateChanged.listen((estado) {
      if (mounted) setState(() => _estado = estado);
    });

    _durationSub = _player.onDurationChanged.listen((duracion) {
      if (mounted) setState(() => _duracion = duracion);
    });

    _positionSub = _player.onPositionChanged.listen((posicion) {
      if (mounted) setState(() => _posicion = posicion);
    });
  }

  Future<void> _alternarReproduccion() async {
    if (_estado == PlayerState.playing) {
      await _player.pause();
    } else if (_estado == PlayerState.paused) {
      await _player.resume();
    } else {
      await _player.play(UrlSource(widget.url));
    }
  }

  @override
  void dispose() {
    _stateSub.cancel();
    _durationSub.cancel();
    _positionSub.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reproduciendo = _estado == PlayerState.playing;
    final double maxSegundos =
        _duracion.inSeconds > 0 ? _duracion.inSeconds.toDouble() : 1.0;
    final double valorActual =
        _posicion.inSeconds.toDouble().clamp(0.0, maxSegundos);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                reproduciendo ? Icons.pause_circle_filled : Icons.play_circle_fill,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: _alternarReproduccion,
            ),
            Expanded(
              child: Slider(
                min: 0,
                max: maxSegundos,
                value: valorActual,
                onChanged: (valor) async {
                  await _player.seek(Duration(seconds: valor.toInt()));
                },
              ),
            ),
            Text(
              '${_posicion.inMinutes}:${(_posicion.inSeconds % 60).toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}