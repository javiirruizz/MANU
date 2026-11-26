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
class SeguimientoPage extends StatefulWidget {
  const SeguimientoPage({super.key});

  @override
  State<SeguimientoPage> createState() => _SeguimientoPageState();
}

class _SeguimientoPageState extends State<SeguimientoPage> {
  final _usuarios = UsuarioRepository();
  final _tareas = TareaRepository();

  List<Usuario> _alumnos = [];
  Usuario? _seleccionado;
  List<Tarea> _historial = [];
  bool _cargandoAlumnos = true;
  bool _cargandoHistorial = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarAlumnos();
  }

  Future<void> _cargarAlumnos() async {
    try {
      final lista = await _usuarios.getAlumnos();
      lista.sort((a, b) => a.nombre.compareTo(b.nombre));
      setState(() {
        _alumnos = lista;
        _cargandoAlumnos = false;
      });
      if (lista.isNotEmpty) _seleccionar(lista.first);
    } catch (e) {
      setState(() {
        _error = 'No se pudieron cargar los alumnos.';
        _cargandoAlumnos = false;
      });
    }
  }

  Future<void> _seleccionar(Usuario alumno) async {
    setState(() {
      _seleccionado = alumno;
      _cargandoHistorial = true;
      _error = null;
    });
    try {
      final h = await _tareas.getHistorialAlumno(alumno.id);
      if (!mounted || _seleccionado?.id != alumno.id) return;
      setState(() {
        _historial = h;
        _cargandoHistorial = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar el historial.';
        _cargandoHistorial = false;
      });
    }
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
            ? const Center(child: Text('Todavía no hay alumnos.'))
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

  Widget _detalle(AppPalette p) {
    final alumno = _seleccionado;
    if (alumno == null) return const SizedBox.shrink();
    if (_cargandoHistorial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(fontSize: 18)));
    }

    final hechas = _historial.where((t) => t.completadaPor.containsKey(alumno.id));
    final totalHechas = hechas.length;
    final pendientes = _historial.length - totalHechas;
    final porcentaje = _historial.isEmpty
        ? 0
        : (totalHechas * 100 / _historial.length).round();

    // Emociones registradas
    final conteo = <String, int>{};
    final atencion = <Tarea>[];
    for (final t in _historial) {
      final v = t.valoraciones[alumno.id];
      if (v == null) continue;
      conteo[v.emocionId] = (conteo[v.emocionId] ?? 0) + 1;
      if (v.requiereAtencion) atencion.add(t);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView(
        children: [
          Row(
            children: [
              AvatarUsuario(nombre: alumno.nombre, fotoUrl: alumno.fotoUrl, size: 64),
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
          const SizedBox(height: 16),
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
              'Todavía no ha registrado ninguna emoción.',
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
          if (atencion.isNotEmpty) ...[
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
                      'Tareas que le generan malestar: '
                      '${atencion.map((t) => t.nombre).toSet().join(', ')}',
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
            'Historial de tareas',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: p.textDark,
            ),
          ),
          const SizedBox(height: 8),
          if (_historial.isEmpty)
            Text(
              'Este alumno todavía no tiene tareas.',
              style: TextStyle(fontSize: 17, color: p.textSoft),
            ),
          ..._filasHistorial(p, alumno.id),
        ],
      ),
    );
  }

  List<Widget> _filasHistorial(AppPalette p, String alumnoId) {
    final filas = <Widget>[];
    DateTime? diaActual;
    for (final t in _historial) {
      final d = DateTime(t.fecha.year, t.fecha.month, t.fecha.day);
      if (diaActual != d) {
        diaActual = d;
        filas.add(
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 6),
            child: Text(
              '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: p.primary,
              ),
            ),
          ),
        );
      }
      filas.add(_FilaTarea(tarea: t, alumnoId: alumnoId));
    }
    return filas;
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
