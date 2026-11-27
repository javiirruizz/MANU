import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../core/app_theme.dart';
import '../../core/tamanos.dart';
import '../../models/tarea.dart';

/// Tiempo que queda de la tarea en curso (HU 17): "Quedan X min" y una barra
/// que se va llenando. Sin porcentaje, sin segundos y sin botón de pausa,
/// para que sea tranquilo de mirar y no agobie.
class BarraProgresoTarea extends StatefulWidget {
  const BarraProgresoTarea({super.key, required this.tarea});

  final Tarea tarea;

  @override
  State<BarraProgresoTarea> createState() => _BarraProgresoTareaState();
}

class _BarraProgresoTareaState extends State<BarraProgresoTarea> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Con minutos basta: no hace falta redibujar cada segundo
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// "Quedan 18 min", "Queda 1 min", "Quedan 1 h y 20 min".
  static String textoRestante(Duration restante) {
    if (restante.inSeconds <= 0) return '¡Se acabó el tiempo!';
    // Redondeamos hacia arriba: con 30 s quedan "1 min", no "0 min"
    final minutosTotales = (restante.inSeconds / 60).ceil();
    final horas = minutosTotales ~/ 60;
    final minutos = minutosTotales % 60;
    if (horas > 0) {
      final h = horas == 1 ? '1 h' : '$horas h';
      return minutos == 0 ? 'Quedan $h' : 'Quedan $h y $minutos min';
    }
    return minutos == 1 ? 'Queda 1 min' : 'Quedan $minutos min';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final inicio = widget.tarea.horaInicio;
    final total = widget.tarea.horaFinal.difference(inicio);
    final duracion = total.inSeconds > 0 ? total : const Duration(minutes: 30);

    final ahora = DateTime.now();
    var transcurrido = ahora.difference(inicio);
    if (transcurrido.isNegative) transcurrido = Duration.zero;
    if (transcurrido > duracion) transcurrido = duracion;

    final progreso = transcurrido.inMilliseconds / duracion.inMilliseconds;
    final restante = duracion - transcurrido;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          textoRestante(restante),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: context.letra(Letra.detalle) * 0.85,
            fontWeight: FontWeight.w800,
            color: p.textDark,
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progreso.clamp(0.0, 1.0),
            minHeight: context.medida(12),
            backgroundColor: p.surface,
            valueColor: AlwaysStoppedAnimation<Color>(p.primary),
          ),
        ),
      ],
    );
  }
}
