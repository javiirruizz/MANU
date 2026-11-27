import 'package:material_ui/material_ui.dart';

import '../../core/app_theme.dart';
import '../../models/mood_option.dart';
import '../../models/tarea.dart';
import '../../viewmodels/agenda_view_model.dart';
import 'pictograma_imagen.dart';

/// HU 22: panel que se abre al terminar una tarea, con caritas y estrellas.
/// Al guardar, la tarea queda completada y con su valoración.
Future<void> mostrarValoracion(
  BuildContext context, {
  required AgendaViewModel vm,
  required Tarea tarea,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ValoracionDialog(
      titulo: '¡Tarea terminada!',
      subtitulo: tarea.nombre,
      preguntaEmocion: '¿Cómo te has sentido?',
      preguntaEstrellas: '¿Te ha gustado?',
      moods: vm.moods,
      onGuardar: (e, s) => vm.guardarValoracion(tarea.id, e, s),
    ),
  );
}

/// Ventana de satisfacción al pulsar "¡Día completado!".
Future<void> mostrarValoracionDia(
  BuildContext context, {
  required AgendaViewModel vm,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ValoracionDialog(
      titulo: '¡Día completado!',
      subtitulo: '${vm.weekdayName} ${vm.dayNumber} de ${vm.monthName}',
      preguntaEmocion: '¿Cómo te has sentido hoy?',
      preguntaEstrellas: '¿Te ha gustado el día?',
      moods: vm.moods,
      onGuardar: vm.guardarValoracionDia,
    ),
  );
}

class _ValoracionDialog extends StatefulWidget {
  const _ValoracionDialog({
    required this.titulo,
    required this.subtitulo,
    required this.preguntaEmocion,
    required this.preguntaEstrellas,
    required this.moods,
    required this.onGuardar,
  });

  final String titulo;
  final String subtitulo;
  final String preguntaEmocion;
  final String preguntaEstrellas;
  final List<MoodOption> moods;
  final Future<bool> Function(String emocionId, int estrellas) onGuardar;

  @override
  State<_ValoracionDialog> createState() => _ValoracionDialogState();
}

class _ValoracionDialogState extends State<_ValoracionDialog> {
  String? _emocion;
  int _estrellas = 0;

  Future<void> _guardar() async {
    final e = _emocion;
    if (e == null) return;
    Navigator.of(context).pop();
    await widget.onGuardar(e, _estrellas);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final alto = MediaQuery.sizeOf(context).height;
    final picto = alto < 900 ? 72.0 : 96.0;
    final moods = widget.moods;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.titulo,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: p.greenDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitulo,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, color: p.textSoft),
              ),
              const SizedBox(height: 18),
              Text(
                widget.preguntaEmocion,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: p.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final m in moods)
                    _Emocion(
                      mood: m,
                      picto: picto,
                      seleccionada: _emocion == m.id,
                      onTap: () => setState(() => _emocion = m.id),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                widget.preguntaEstrellas,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: p.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 1; i <= 5; i++)
                    Semantics(
                      button: true,
                      label: '$i estrellas',
                      child: IconButton(
                        iconSize: 54,
                        onPressed: () => setState(
                          () => _estrellas = _estrellas == i ? 0 : i,
                        ),
                        icon: Icon(
                          i <= _estrellas ? Icons.star : Icons.star_border,
                          color: p.amber,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(64),
                      ),
                      child: const Text(
                        'Ahora no',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _emocion == null ? null : _guardar,
                      icon: const Icon(Icons.check, size: 28),
                      label: const Text(
                        'GUARDAR',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: p.greenDark,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(64),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Emocion extends StatelessWidget {
  const _Emocion({
    required this.mood,
    required this.picto,
    required this.seleccionada,
    required this.onTap,
  });

  final MoodOption mood;
  final double picto;
  final bool seleccionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: seleccionada ? p.green : Colors.transparent,
        width: 4,
      ),
    );
    return Semantics(
      button: true,
      selected: seleccionada,
      label: mood.label,
      excludeSemantics: true,
      child: Material(
        color: seleccionada ? p.selectedBg : p.cardTint,
        shape: forma,
        child: InkWell(
          customBorder: forma,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PictogramaImagen(
                  consulta: mood.label.toLowerCase(),
                  size: picto,
                  iconoReserva: mood.icon,
                ),
                const SizedBox(height: 6),
                Text(
                  mood.label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: p.textDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
