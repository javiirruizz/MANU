import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../core/app_theme.dart';
import '../../data/tarea_repository.dart';
import '../../data/usuario_repository.dart';
import '../../models/tarea.dart';
import '../../models/usuario.dart';
import '../../models/valoracion.dart';
import '../widgets/avatar_usuario.dart';
import '../widgets/pictograma_imagen.dart';

/// HU 29: panel de seguimiento integral del alumno (progreso y emociones).
/// Muestra una semana (por defecto la actual); el profesor puede cambiarla.
class SeguimientoPage extends StatefulWidget {
  const SeguimientoPage({super.key});

  @override
  State<SeguimientoPage> createState() => _SeguimientoPageState();
}

class _SeguimientoPageState extends State<SeguimientoPage> {
  static const _meses = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];
  static const _dias = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  final _usuarios = UsuarioRepository();
  final _tareas = TareaRepository();

  List<Usuario> _alumnos = [];
  Usuario? _seleccionado;
  DateTime _lunes = _lunesDe(DateTime.now());
  List<Tarea> _historial = [];
  Map<DateTime, ValoracionTarea> _valoracionesDia = {};
  StreamSubscription<List<Tarea>>? _subTareas;
  StreamSubscription<Map<DateTime, ValoracionTarea>>? _subDias;
  bool _cargandoAlumnos = true;
  bool _cargandoHistorial = false;
  String? _error;

  static DateTime _lunesDe(DateTime d) =>
      DateTime(d.year, d.month, d.day - (d.weekday - 1));

  bool get _esSemanaActual => _lunes == _lunesDe(DateTime.now());

  String get _textoSemana {
    final dom = DateTime(_lunes.year, _lunes.month, _lunes.day + 6);
    final mesL = _meses[_lunes.month - 1];
    final mesD = _meses[dom.month - 1];
    return _lunes.month == dom.month
        ? 'Semana del ${_lunes.day} al ${dom.day} de $mesD'
        : 'Semana del ${_lunes.day} de $mesL al ${dom.day} de $mesD';
  }

  @override
  void initState() {
    super.initState();
    _cargarAlumnos();
  }

  @override
  void dispose() {
    _subTareas?.cancel();
    _subDias?.cancel();
    super.dispose();
  }

  Future<void> _cargarAlumnos() async {
    try {
      final lista = await _usuarios.getAlumnos();
      lista.sort((a, b) => a.nombre.compareTo(b.nombre));
      if (!mounted) return;
      setState(() {
        _alumnos = lista;
        _cargandoAlumnos = false;
      });
      if (lista.isNotEmpty) _seleccionar(lista.first);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar los alumnos.';
        _cargandoAlumnos = false;
      });
    }
  }

  void _seleccionar(Usuario alumno) {
    _seleccionado = alumno;
    _escuchar();
  }

  void _cambiarSemana(DateTime dia) {
    _lunes = _lunesDe(dia);
    _escuchar();
  }

  Future<void> _elegirSemana() async {
    final elegido = await showDatePicker(
      context: context,
      initialDate: _lunes,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030, 12, 31),
      helpText: 'Elige un día de la semana',
    );
    if (elegido != null) _cambiarSemana(elegido);
  }

  /// Escucha en tiempo real las tareas y las valoraciones de día del alumno
  /// seleccionado en la semana elegida.
  void _escuchar() {
    final alumno = _seleccionado;
    if (alumno == null) return;
    _subTareas?.cancel();
    _subDias?.cancel();
    setState(() {
      _cargandoHistorial = true;
      _error = null;
      _historial = [];
      _valoracionesDia = {};
    });
    _subTareas = _tareas
        .streamTareasAlumnoSemana(alumno.id, _lunes)
        .listen(
          (lista) {
            if (!mounted) return;
            setState(() {
              _historial = lista;
              _cargandoHistorial = false;
            });
          },
          onError: (Object e) {
            if (!mounted) return;
            setState(() {
              _error = 'No se pudo cargar el historial.';
              _cargandoHistorial = false;
            });
          },
        );
    _subDias = _tareas.streamValoracionesDiaSemana(alumno.id, _lunes).listen((
      m,
    ) {
      if (mounted) setState(() => _valoracionesDia = m);
    }, onError: (Object e) => debugPrint('Valoraciones de día: $e'));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Panel de seguimiento',
          style: TextStyle(color: p.primary, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: _cargandoAlumnos
            ? const Center(child: CircularProgressIndicator())
            : _alumnos.isEmpty
            ? Center(child: Text(_error ?? 'Todavía no hay alumnos.'))
            : Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: 270, child: _listaAlumnos(p)),
                    const SizedBox(width: 12),
                    Expanded(child: _detalle(p)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _listaAlumnos(AppPalette p) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView.separated(
        itemCount: _alumnos.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final a = _alumnos[i];
          final sel = a.id == _seleccionado?.id;
          return Material(
            color: sel ? p.cardTint : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _seleccionar(a),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    AvatarUsuario(
                      nombre: a.nombre,
                      fotoUrl: a.fotoUrl,
                      size: 52,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        a.nombre,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: p.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _selectorSemana(AppPalette p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: p.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Semana anterior',
            onPressed: () => _cambiarSemana(
              DateTime(_lunes.year, _lunes.month, _lunes.day - 7),
            ),
            icon: Icon(Icons.chevron_left, color: p.primary, size: 30),
          ),
          Expanded(
            child: Text(
              _textoSemana,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: p.textDark,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Semana siguiente',
            onPressed: () => _cambiarSemana(
              DateTime(_lunes.year, _lunes.month, _lunes.day + 7),
            ),
            icon: Icon(Icons.chevron_right, color: p.primary, size: 30),
          ),
          const SizedBox(width: 4),
          if (!_esSemanaActual) ...[
            TextButton(
              onPressed: () => _cambiarSemana(DateTime.now()),
              child: const Text('Esta semana'),
            ),
            const SizedBox(width: 4),
          ],
          OutlinedButton.icon(
            onPressed: _elegirSemana,
            icon: const Icon(Icons.calendar_month),
            label: const Text('Elegir semana'),
          ),
        ],
      ),
    );
  }

  Widget _detalle(AppPalette p) {
    final alumno = _seleccionado;
    if (alumno == null) return const SizedBox.shrink();

    final cabecera = [
      Row(
        children: [
          AvatarUsuario(
            nombre: alumno.nombre,
            fotoUrl: alumno.fotoUrl,
            size: 64,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              alumno.nombre,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: p.textDark,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _selectorSemana(p),
      const SizedBox(height: 16),
    ];

    Widget caja(List<Widget> hijos) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView(children: [...cabecera, ...hijos]),
    );

    if (_cargandoHistorial) {
      return caja([
        const Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        ),
      ]);
    }
    if (_error != null) {
      return caja([
        Center(child: Text(_error!, style: const TextStyle(fontSize: 18))),
      ]);
    }

    final totalHechas = _historial
        .where((t) => t.completadaPor.containsKey(alumno.id))
        .length;
    final pendientes = _historial.length - totalHechas;
    final porcentaje = _historial.isEmpty
        ? 0
        : (totalHechas * 100 / _historial.length).round();

    // Emociones registradas (al terminar tareas y al terminar el día)
    final conteo = <String, int>{};
    final atencion = <Tarea>[];
    for (final t in _historial) {
      final v = t.valoraciones[alumno.id];
      if (v == null) continue;
      conteo[v.emocionId] = (conteo[v.emocionId] ?? 0) + 1;
      if (v.requiereAtencion) atencion.add(t);
    }
    final diasMalos = <DateTime>[];
    for (final e in _valoracionesDia.entries) {
      conteo[e.value.emocionId] = (conteo[e.value.emocionId] ?? 0) + 1;
      if (e.value.requiereAtencion) diasMalos.add(e.key);
    }
    diasMalos.sort();

    final avisos = [
      if (atencion.isNotEmpty)
        'Tareas que le generan malestar: '
            '${atencion.map((t) => t.nombre).toSet().join(', ')}',
      if (diasMalos.isNotEmpty)
        'Días que no se ha sentido bien: '
            '${diasMalos.map((d) => '${_dias[d.weekday - 1]} ${d.day}').join(', ')}',
    ];

    return caja([
      Row(
        children: [
          _Dato(
            valor: '$totalHechas',
            etiqueta: 'Completadas',
            color: p.greenDark,
            fondo: p.greenSoft,
          ),
          const SizedBox(width: 10),
          _Dato(
            valor: '$pendientes',
            etiqueta: 'Pendientes',
            color: p.orange,
            fondo: p.orangeSoft,
          ),
          const SizedBox(width: 10),
          _Dato(
            valor: '$porcentaje%',
            etiqueta: 'Realizado',
            color: p.primary,
            fondo: p.badge,
          ),
        ],
      ),
      const SizedBox(height: 12),
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LinearProgressIndicator(
          value: _historial.isEmpty ? 0 : totalHechas / _historial.length,
          minHeight: 18,
          backgroundColor: p.orangeSoft,
          color: p.green,
        ),
      ),
      for (final texto in avisos) ...[
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.orangeSoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.orange, width: 2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, color: p.orange, size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  texto,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: p.textDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      const SizedBox(height: 20),
      Text(
        'Emociones registradas',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: p.textDark,
        ),
      ),
      const SizedBox(height: 8),
      if (conteo.isEmpty)
        Text(
          'Esta semana todavía no ha registrado ninguna emoción.',
          style: TextStyle(fontSize: 17, color: p.textSoft),
        )
      else
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final e in conteo.entries)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: p.cardTint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PictogramaImagen(consulta: e.key, size: 56),
                    const SizedBox(width: 10),
                    Text(
                      '${ValoracionTarea.etiquetaEmocion(e.key)}  ×${e.value}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: p.textDark,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      const SizedBox(height: 20),
      Text(
        'Tareas de la semana',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: p.textDark,
        ),
      ),
      const SizedBox(height: 8),
      if (_historial.isEmpty)
        Text(
          'No tiene tareas esta semana.',
          style: TextStyle(fontSize: 17, color: p.textSoft),
        ),
      ..._filasHistorial(p, alumno.id),
    ]);
  }

  List<Widget> _filasHistorial(AppPalette p, String alumnoId) {
    final filas = <Widget>[];
    DateTime? diaActual;
    for (final t in _historial) {
      final d = DateTime(t.fecha.year, t.fecha.month, t.fecha.day);
      if (diaActual != d) {
        diaActual = d;
        final vDia = _valoracionesDia[d];
        final mes = d.month.toString().padLeft(2, '0');
        filas.add(
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 6),
            child: Row(
              children: [
                Text(
                  '${_dias[d.weekday - 1]} ${d.day}/$mes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: p.primary,
                  ),
                ),
                if (vDia != null) ...[
                  const SizedBox(width: 12),
                  _ValoracionDiaChip(v: vDia),
                ],
              ],
            ),
          ),
        );
      }
      filas.add(_FilaTarea(tarea: t, alumnoId: alumnoId));
    }
    return filas;
  }
}

/// Cómo dijo el alumno que le fue el día (botón "¡Día completado!").
class _ValoracionDiaChip extends StatelessWidget {
  const _ValoracionDiaChip({required this.v});

  final ValoracionTarea v;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: v.requiereAtencion ? p.orangeSoft : p.greenSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PictogramaImagen(consulta: v.emocionId, size: 30),
          const SizedBox(width: 6),
          Text(
            'Día: ${v.emocionEtiqueta}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: p.textDark,
            ),
          ),
          const SizedBox(width: 6),
          for (var i = 1; i <= 5; i++)
            Icon(
              i <= v.estrellas ? Icons.star : Icons.star_border,
              size: 16,
              color: p.amber,
            ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({
    required this.valor,
    required this.etiqueta,
    required this.color,
    required this.fondo,
  });

  final String valor;
  final String etiqueta;
  final Color color;
  final Color fondo;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              valor,
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              etiqueta,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaTarea extends StatelessWidget {
  const _FilaTarea({required this.tarea, required this.alumnoId});

  final Tarea tarea;
  final String alumnoId;

  static String _h(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final hecha = tarea.completadaPor.containsKey(alumnoId);
    final v = tarea.valoraciones[alumnoId];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: (v?.requiereAtencion ?? false) ? p.orangeSoft : p.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          PictogramaImagen(
            id: tarea.pictogramaId,
            consulta: tarea.nombre,
            size: 56,
            iconoReserva: Icons.event_note_outlined,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tarea.nombre,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: p.textDark,
                  ),
                ),
                Text(
                  '${_h(tarea.horaInicio)} - ${_h(tarea.horaFinal)}',
                  style: TextStyle(fontSize: 15, color: p.textSoft),
                ),
              ],
            ),
          ),
          if (v != null) ...[
            PictogramaImagen(consulta: v.emocionId, size: 52),
            const SizedBox(width: 8),
            SizedBox(
              width: 110,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    v.emocionEtiqueta,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: p.textDark,
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 1; i <= 5; i++)
                        Icon(
                          i <= v.estrellas ? Icons.star : Icons.star_border,
                          size: 18,
                          color: p.amber,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: hecha ? p.greenSoft : p.orangeSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hecha ? Icons.check_circle : Icons.hourglass_empty,
                  color: hecha ? p.greenDark : p.orange,
                  size: 22,
                ),
                const SizedBox(width: 6),
                Text(
                  hecha ? 'Hecha' : 'Pendiente',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: hecha ? p.greenDark : p.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
