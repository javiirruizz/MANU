import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../data/audio_service.dart';
import '../../models/tarea.dart';

/// Barra de progreso visual y pausable para la tarea en curso (HU 17).
class BarraProgresoPausable extends StatefulWidget {
  const BarraProgresoPausable({
    super.key,
    required this.tarea,
  });

  final Tarea tarea;

  @override
  State<BarraProgresoPausable> createState() => _BarraProgresoPausableState();
}

class _BarraProgresoPausableState extends State<BarraProgresoPausable> {
  final AudioService _audio = AudioService();
  Timer? _timer;

  bool _pausado = false;
  DateTime? _inicioPausa;
  Duration _pausaAcumulada = Duration.zero;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_pausado && mounted) {
        setState(() {});
      }
    });
  }

  @override
  void didUpdateWidget(covariant BarraProgresoPausable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tarea.id != widget.tarea.id) {
      _pausado = false;
      _inicioPausa = null;
      _pausaAcumulada = Duration.zero;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _alternarPausa() {
    setState(() {
      if (_pausado) {
        if (_inicioPausa != null) {
          _pausaAcumulada += DateTime.now().difference(_inicioPausa!);
        }
        _inicioPausa = null;
        _pausado = false;
        _audio.leerTexto('Tarea reanudada');
      } else {
        _inicioPausa = DateTime.now();
        _pausado = true;
        _audio.leerTexto('Tarea en pausa');
      }
    });
  }

  String _formatearRestante(Duration restante) {
    if (restante.inSeconds <= 0) return 'Tiempo completado';
    final horas = restante.inHours;
    final minutos = restante.inMinutes.remainder(60);
    final segundos = restante.inSeconds.remainder(60);

    if (horas > 0) {
      return 'Quedan ${horas}h ${minutos}min';
    }
    if (minutos > 0) {
      return 'Quedan $minutos min ${segundos.toString().padLeft(2, '0')} s';
    }
    return 'Quedan $segundos s';
  }

  @override
  Widget build(BuildContext context) {
    final totalBruto = widget.tarea.horaFinal.difference(widget.tarea.horaInicio);
    final total = totalBruto.inSeconds > 0
        ? totalBruto
        : const Duration(minutes: 30);

    final ahoraEfectivo =
        _pausado && _inicioPausa != null ? _inicioPausa! : DateTime.now();

    var transcurrido =
        ahoraEfectivo.difference(widget.tarea.horaInicio) - _pausaAcumulada;
    if (transcurrido.isNegative) {
      transcurrido = Duration.zero;
    } else if (transcurrido > total) {
      transcurrido = total;
    }

    final progreso =
        (transcurrido.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
    final restante = total - transcurrido;
    final porcentaje = (progreso * 100).round();

    final colorPrincipal = _pausado ? AppColors.orange : AppColors.primary;
    final colorFondo = _pausado ? AppColors.orangeSoft : AppColors.surface;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _pausado ? AppColors.orange : AppColors.primary.withAlpha(80),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _pausado ? Icons.pause_circle_filled : Icons.timelapse,
            color: colorPrincipal,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _pausado ? 'EN PAUSA · $porcentaje%' : 'Progreso · $porcentaje%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: colorPrincipal,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatearRestante(restante),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progreso,
                    minHeight: 14,
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(colorPrincipal),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          FilledButton.icon(
            onPressed: _alternarPausa,
            style: FilledButton.styleFrom(
              backgroundColor: _pausado ? AppColors.greenDark : AppColors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: Icon(
              _pausado ? Icons.play_arrow_rounded : Icons.pause_rounded,
              size: 24,
            ),
            label: Text(
              _pausado ? 'Reanudar' : 'Pausar',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}