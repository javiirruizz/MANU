import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../core/app_theme.dart';
import '../../core/tamanos.dart';
import '../../data/arasaac_service.dart';
import '../../data/tarea_repository.dart';
import '../../models/paso.dart';
import '../../models/tarea.dart';
import '../../models/usuario.dart';
import 'pictograma_imagen.dart';

/// Ventana sencilla para que el alumno añada una tarea suya para hoy.
/// Solo aparece si el profesor le ha dado el permiso "Crear mis propias
/// tareas". El dibujo se busca solo en ARASAAC a partir del nombre.
Future<void> mostrarCrearTarea(
  BuildContext context, {
  required Usuario alumno,
  TareaRepository? repositorio,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _CrearTareaDialog(
      alumno: alumno,
      repo: repositorio ?? TareaRepository(),
    ),
  );
}

class _CrearTareaDialog extends StatefulWidget {
  const _CrearTareaDialog({required this.alumno, required this.repo});

  final Usuario alumno;
  final TareaRepository repo;

  @override
  State<_CrearTareaDialog> createState() => _CrearTareaDialogState();
}

class _CrearTareaDialogState extends State<_CrearTareaDialog> {
  final _nombre = TextEditingController();
  late TimeOfDay _inicio;
  late TimeOfDay _fin;
  String _consulta = ''; // texto con el que se busca el dibujo
  Timer? _espera;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Por defecto: desde la próxima media hora, durante 30 minutos
    final ahora = DateTime.now();
    final redondeo = DateTime(
      ahora.year,
      ahora.month,
      ahora.day,
      ahora.hour,
      ahora.minute < 30 ? 30 : 60,
    );
    _inicio = TimeOfDay.fromDateTime(redondeo);
    _fin = TimeOfDay.fromDateTime(redondeo.add(const Duration(minutes: 30)));
    _nombre.addListener(() {
      // Esperamos a que deje de escribir para buscar el dibujo
      _espera?.cancel();
      _espera = Timer(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _consulta = _nombre.text.trim());
      });
    });
  }

  @override
  void dispose() {
    _espera?.cancel();
    _nombre.dispose();
    super.dispose();
  }

  static int _minutos(TimeOfDay t) => t.hour * 60 + t.minute;

  static String _texto(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _elegirHora({required bool inicio}) async {
    final elegida = await showTimePicker(
      context: context,
      initialTime: inicio ? _inicio : _fin,
      helpText: inicio ? '¿A qué hora empieza?' : '¿A qué hora termina?',
    );
    if (elegida == null) return;
    setState(() {
      if (inicio) {
        _inicio = elegida;
        if (_minutos(_fin) <= _minutos(_inicio)) {
          final m = _minutos(_inicio) + 30;
          _fin = TimeOfDay(hour: (m ~/ 60).clamp(0, 23), minute: m % 60);
        }
      } else {
        _fin = elegida;
      }
    });
  }

  Future<void> _guardar() async {
    final nombre = _nombre.text.trim();
    if (nombre.isEmpty) {
      setState(() => _error = 'Escribe qué vas a hacer.');
      return;
    }
    if (_minutos(_fin) <= _minutos(_inicio)) {
      setState(() => _error = 'La hora de terminar tiene que ser después.');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });

    final hoy = DateTime.now();
    DateTime a(TimeOfDay t) =>
        DateTime(hoy.year, hoy.month, hoy.day, t.hour, t.minute);
    final pictogramaId = await ArasaacService.instance.buscarId(nombre);

    final tarea = Tarea(
      id: '',
      nombre: nombre,
      descripcion: '',
      fecha: DateTime(hoy.year, hoy.month, hoy.day),
      horario: _inicio.hour < 14 ? 'mañana' : 'tarde',
      horaInicio: a(_inicio),
      horaFinal: a(_fin),
      aulaId: '',
      creadaPor: widget.alumno.id,
      alumnoIds: [widget.alumno.id],
      // El paso único guarda el dibujo de la tarea
      pasos: [
        Paso(
          id: '1',
          descripcion: nombre,
          orden: 1,
          pictogramaId: pictogramaId?.toString(),
        ),
      ],
    );

    try {
      await widget.repo.guardarTarea(tarea);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '¡Tarea añadida!',
            style: TextStyle(fontSize: context.letra(Letra.detalle)),
          ),
          backgroundColor: context.palette.greenDark,
        ),
      );
    } catch (e) {
      debugPrint('Error creando tarea del alumno: $e');
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = 'No se ha podido guardar. Inténtalo otra vez.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final estiloEtiqueta = TextStyle(
      fontSize: context.letra(Letra.normal),
      fontWeight: FontWeight.w800,
      color: p.textDark,
    );

    Widget botonHora(String etiqueta, TimeOfDay hora, bool inicio) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(etiqueta, style: estiloEtiqueta, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: _guardando ? null : () => _elegirHora(inicio: inicio),
            icon: Icon(Icons.schedule, size: context.medida(28)),
            label: Text(
              _texto(hora),
              style: TextStyle(
                fontSize: context.letra(Letra.destacado),
                fontWeight: FontWeight.w800,
              ),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: Size.fromHeight(context.medida(64)),
            ),
          ),
        ],
      ),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.medida(620)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: p.primary,
                    size: context.medida(38),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Nueva tarea',
                    style: TextStyle(
                      fontSize: context.letra(Letra.destacado),
                      fontWeight: FontWeight.w800,
                      color: p.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  // El dibujo aparece solo al escribir
                  Container(
                    width: context.medida(110),
                    height: context.medida(110),
                    decoration: BoxDecoration(
                      color: p.cardTint,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: _consulta.isEmpty
                        ? Icon(
                            Icons.image_outlined,
                            size: context.medida(48),
                            color: p.textSoft,
                          )
                        : PictogramaImagen(
                            key: ValueKey(_consulta),
                            consulta: _consulta,
                            size: context.medida(96),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('¿Qué vas a hacer?', style: estiloEtiqueta),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _nombre,
                          autofocus: true,
                          enabled: !_guardando,
                          textCapitalization: TextCapitalization.sentences,
                          style: TextStyle(
                            fontSize: context.letra(Letra.normal),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Por ejemplo: Leer un cuento',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onSubmitted: (_) => _guardar(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  botonHora('Empieza', _inicio, true),
                  const SizedBox(width: 14),
                  botonHora('Termina', _fin, false),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: context.letra(Letra.detalle),
                    fontWeight: FontWeight.w700,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _guardando
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size.fromHeight(context.medida(64)),
                      ),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(fontSize: context.letra(Letra.normal)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _guardando ? null : _guardar,
                      icon: _guardando
                          ? SizedBox(
                              width: context.medida(24),
                              height: context.medida(24),
                              child: const CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                              ),
                            )
                          : Icon(Icons.check, size: context.medida(30)),
                      label: Text(
                        'AÑADIR',
                        style: TextStyle(
                          fontSize: context.letra(Letra.normal),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: p.greenDark,
                        minimumSize: Size.fromHeight(context.medida(64)),
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
