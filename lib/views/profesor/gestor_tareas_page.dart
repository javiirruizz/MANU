import 'package:material_ui/material_ui.dart';

import '../../core/app_colors.dart';
import '../../models/paso.dart';
import '../../models/tarea.dart';
import '../../models/usuario.dart';
import '../../data/agenda_pdf_service.dart';
import '../../models/menu.dart';
import '../../core/app_theme.dart';
import '../widgets/pictograma_imagen.dart';

enum TipoAsignacion { individual, grupal, recurrente }

enum FrecuenciaRecurrencia { diario, semanal, diasLectivos }

/// Pantalla del Gestor de Planificación y Asignación de Tareas (HU 07 & HU 08.2).
class GestorTareasPage extends StatefulWidget {
  const GestorTareasPage({
    super.key,
    this.alumnos = const [],
    this.tareas = const [],
    this.aulas = const [],
    this.profesorId = '',
    required this.fechaSeleccionada,
    this.onGuardarTarea,
    this.onActualizarTarea,
    this.onEliminarTarea,
    this.onFechaCambiada,
    this.subiendoMultimedia = false,
    this.onSubirVideo,
    this.onSubirAudio,
    this.onObtenerMenusSemana,
  });

  final List<Usuario> alumnos;
  final List<Tarea> tareas;
  final List<String> aulas;
  final String profesorId;
  final bool subiendoMultimedia;
  final Future<String?> Function()? onSubirVideo;
  final Future<String?> Function()? onSubirAudio;
  final Future<List<Menu>> Function(String comedorId, DateTime lunes)?
  onObtenerMenusSemana;

  final Future<void> Function(
    Tarea nuevaTarea,
    TipoAsignacion tipo,
    FrecuenciaRecurrencia? recurrencia,
  )?
  onGuardarTarea;
  final Future<void> Function(Tarea tareaActualizada)? onActualizarTarea;
  final Future<void> Function(String tareaId)? onEliminarTarea;
  final Future<void> Function(DateTime nuevaFecha)? onFechaCambiada;
  final DateTime fechaSeleccionada;

  @override
  State<GestorTareasPage> createState() => _GestorTareasPageState();
}

class _GestorTareasPageState extends State<GestorTareasPage> {
  // ---- Filtros del Cronograma ----
  late DateTime _fechaSeleccionada;

  @override
  void initState() {
    super.initState();
    _fechaSeleccionada = widget.fechaSeleccionada;
  }

  String? _filtroAlumnoId;
  final _filtroAulaCtrl = TextEditingController();

  // ---- Tarea en Edición ----
  Tarea? _tareaEnEdicion;

  // ---- Formulario de Asignación ----
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _aulaCtrl = TextEditingController();
  final _enlaceWebCtrl = TextEditingController();
  final _nuevoPasoCtrl = TextEditingController();
  List<Paso> _pasos = [];
  String? _audioUrl;
  String? _videoUrl;

  TipoAsignacion _tipoAsignacion = TipoAsignacion.individual;
  FrecuenciaRecurrencia _frecuencia = FrecuenciaRecurrencia.semanal;

  String? _alumnoSeleccionadoId;
  final Set<String> _alumnosGrupalesIds = {};

  TimeOfDay _horaInicio = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _horaFin = const TimeOfDay(hour: 10, minute: 0);

  bool _guardando = false;

  DateTime _lunesDe(DateTime f) =>
      DateTime(f.year, f.month, f.day).subtract(Duration(days: f.weekday - 1));

  /// Pictograma de la tarea: el primero asociado o, si no, el del último paso.
  String? _urlPictograma(Tarea t) {
    if (t.pictogramas.isNotEmpty) {
      final u = t.pictogramas.first.urlResuelta;
      return u.startsWith('http') ? u : null;
    }
    final id = t.pictogramaId;
    if (id == null || id.isEmpty) return null;
    return 'https://static.arasaac.org/pictograms/$id/${id}_300.png';
  }

  String? _urlPlato(PlatoMenu p) {
    final url = p.pictogramaUrl;
    if (url != null && url.startsWith('http')) return url;
    final id = p.pictogramaId;
    // Los pictogramas subidos por el centro ("custom_...") no están en ARASAAC
    if (id == null || id.isEmpty || id.startsWith('custom_')) return null;
    return 'https://static.arasaac.org/pictograms/$id/${id}_300.png';
  }

  List<PlatoPdf> _platosPdf(Menu? m) {
    if (m == null) return const [];
    return [
      PlatoPdf(
        etiqueta: '1º plato',
        nombre: m.primerPlato.nombre,
        pictogramaUrl: _urlPlato(m.primerPlato),
      ),
      PlatoPdf(
        etiqueta: '2º plato',
        nombre: m.segundoPlato.nombre,
        pictogramaUrl: _urlPlato(m.segundoPlato),
      ),
      PlatoPdf(
        etiqueta: 'Postre',
        nombre: m.postre.nombre,
        pictogramaUrl: _urlPlato(m.postre),
      ),
    ];
  }

  Future<void> _exportar({required bool imprimir}) async {
    final messenger = ScaffoldMessenger.of(context);
    final lunes = _lunesDe(_fechaSeleccionada);
    final domingo = lunes.add(const Duration(days: 6));

    // Tareas de la semana, de un alumno o de todos (grupo)
    final semana = widget.tareas.where((t) {
      final f = DateTime(t.fecha.year, t.fecha.month, t.fecha.day);
      final enSemana = !f.isBefore(lunes) && !f.isAfter(domingo);
      final delAlumno =
          _filtroAlumnoId == null || t.alumnoIds.contains(_filtroAlumnoId);
      return enSemana && delAlumno;
    }).toList();

    if (semana.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('No hay tareas esta semana para exportar.'),
        ),
      );
      return;
    }

    // Comedor del alumno filtrado (o el principal en la vista de grupo)
    final comedorId =
        widget.alumnos
            .where((a) => a.id == _filtroAlumnoId)
            .map((a) => a.comedorId)
            .firstOrNull ??
        'comedor_principal';

    var menus = <Menu>[];
    if (widget.onObtenerMenusSemana != null) {
      try {
        menus = await widget.onObtenerMenusSemana!(comedorId, lunes);
      } catch (_) {
        // Sin menú: se imprime el bloque vacío
      }
    }

    Menu? menuDe(DateTime d) => menus
        .where(
          (m) =>
              m.fecha.year == d.year &&
              m.fecha.month == d.month &&
              m.fecha.day == d.day,
        )
        .firstOrNull;

    final dias = <DiaPdf>[];
    for (var i = 0; i < 7; i++) {
      final dia = lunes.add(Duration(days: i));
      final delDia =
          semana
              .where(
                (t) =>
                    t.fecha.year == dia.year &&
                    t.fecha.month == dia.month &&
                    t.fecha.day == dia.day,
              )
              .toList()
            ..sort((a, b) => a.horaInicio.compareTo(b.horaInicio));
      if (i >= 5 && delDia.isEmpty) continue; // fin de semana vacío

      dias.add(
        DiaPdf(
          fecha: dia,
          menu: _platosPdf(menuDe(dia)),
          tareas: [
            for (final t in delDia)
              TareaPdf(
                inicio: t.horaInicio,
                fin: t.horaFinal,
                nombre: t.nombre,
                pictogramaUrl: _urlPictograma(t),
              ),
          ],
        ),
      );
    }

    final nombreAlumno = _filtroAlumnoId == null
        ? 'Todos los alumnos'
        : widget.alumnos
              .firstWhere(
                (a) => a.id == _filtroAlumnoId,
                orElse: () => Usuario(
                  id: '',
                  nombreUsuario: '',
                  nombre: 'Alumno',
                  rol: RolUsuario.alumno,
                ),
              )
              .nombre;

    messenger.showSnackBar(
      const SnackBar(content: Text('Preparando el documento...')),
    );

    try {
      final servicio = AgendaPdfService();
      final bytes = await servicio.generar(
        titulo: 'Agenda · $nombreAlumno',
        dias: dias,
      );
      final archivo = 'agenda_${lunes.year}-${lunes.month}-${lunes.day}';
      if (imprimir) {
        await servicio.imprimir(bytes, archivo);
      } else {
        await servicio.compartir(bytes, archivo);
      }
    } catch (e, st) {
      debugPrint('Error PDF: $e\n$st');
      messenger.showSnackBar(
        SnackBar(content: Text('No se pudo generar el PDF: $e')),
      );
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    _aulaCtrl.dispose();
    _filtroAulaCtrl.dispose();
    _enlaceWebCtrl.dispose();
    _nuevoPasoCtrl.dispose();
    super.dispose();
  }

  void _cambiarDia(int dias) {
    final nuevaFecha = _fechaSeleccionada.add(Duration(days: dias));
    setState(() => _fechaSeleccionada = nuevaFecha);
    if (widget.onFechaCambiada != null) {
      widget.onFechaCambiada!(nuevaFecha);
    }
  }

  void _limpiarFormulario() {
    _formKey.currentState?.reset();
    _nombreCtrl.clear();
    _descCtrl.clear();
    _aulaCtrl.clear();
    _enlaceWebCtrl.clear();
    _nuevoPasoCtrl.clear();
    setState(() {
      _tareaEnEdicion = null;
      _pasos = [];
      _alumnoSeleccionadoId = null;
      _audioUrl = null;
      _videoUrl = null;
      _alumnosGrupalesIds.clear();
      _tipoAsignacion = TipoAsignacion.individual;
      _frecuencia = FrecuenciaRecurrencia.semanal;
      _horaInicio = const TimeOfDay(hour: 9, minute: 0);
      _horaFin = const TimeOfDay(hour: 10, minute: 0);
    });
  }

  void _cargarTareaParaEdicion(Tarea tarea) {
    setState(() {
      _tareaEnEdicion = tarea;
      _nombreCtrl.text = tarea.nombre;
      _descCtrl.text = tarea.descripcion;
      _aulaCtrl.text = tarea.aulaId;
      _enlaceWebCtrl.text = tarea.enlaceWeb ?? '';
      _nuevoPasoCtrl.clear();
      _pasos = List<Paso>.from(tarea.pasos)
        ..sort((a, b) => a.orden.compareTo(b.orden));
      _audioUrl = tarea.audioUrl;
      _videoUrl = tarea.videoUrl;
      _horaInicio = TimeOfDay.fromDateTime(tarea.horaInicio);
      _horaFin = TimeOfDay.fromDateTime(tarea.horaFinal);

      if (tarea.alumnoIds.length == 1) {
        _tipoAsignacion = TipoAsignacion.individual;
        _alumnoSeleccionadoId = tarea.alumnoIds.first;
        _alumnosGrupalesIds.clear();
      } else {
        _tipoAsignacion = TipoAsignacion.grupal;
        _alumnoSeleccionadoId = null;
        _alumnosGrupalesIds.clear();
        _alumnosGrupalesIds.addAll(tarea.alumnoIds);
      }
    });
  }

  List<Paso> _renumerarPasos(List<Paso> lista) => [
    for (var i = 0; i < lista.length; i++) lista[i].copyWith(orden: i + 1),
  ];

  void _agregarPaso() {
    final texto = _nuevoPasoCtrl.text.trim();
    if (texto.isEmpty) return;

    final nuevo = Paso(
      id: 'paso_${DateTime.now().microsecondsSinceEpoch}_${_pasos.length + 1}',
      descripcion: texto,
      orden: _pasos.length + 1,
    );
    _nuevoPasoCtrl.clear();
    setState(() => _pasos = [..._pasos, nuevo]);
  }

  void _reordenarPasos(int oldIndex, int newIndex) {
    final lista = List<Paso>.from(_pasos);
    final movido = lista.removeAt(oldIndex);
    lista.insert(newIndex, movido);
    setState(() => _pasos = _renumerarPasos(lista));
  }

  void _moverPaso(int index, int delta) {
    final destino = index + delta;
    if (destino < 0 || destino >= _pasos.length) return;
    final lista = List<Paso>.from(_pasos);
    final movido = lista.removeAt(index);
    lista.insert(destino, movido);
    setState(() => _pasos = _renumerarPasos(lista));
  }

  Future<void> _editarPaso(int index) async {
    final nuevoTexto = await showDialog<String>(
      context: context,
      builder: (_) =>
          _EditarPasoDialog(descripcionInicial: _pasos[index].descripcion),
    );
    if (nuevoTexto == null || !mounted) return;
    setState(() {
      final lista = List<Paso>.from(_pasos);
      lista[index] = lista[index].copyWith(descripcion: nuevoTexto);
      _pasos = lista;
    });
  }

  void _eliminarPaso(int index) {
    final lista = List<Paso>.from(_pasos)..removeAt(index);
    setState(() => _pasos = _renumerarPasos(lista));
  }

  DateTime _combinarFechaYHora(DateTime fecha, TimeOfDay hora) {
    return DateTime(fecha.year, fecha.month, fecha.day, hora.hour, hora.minute);
  }

  List<Tarea> _obtenerSolapamientos() {
    final nuevaInicio = _combinarFechaYHora(_fechaSeleccionada, _horaInicio);
    final nuevaFin = _combinarFechaYHora(_fechaSeleccionada, _horaFin);

    if (!nuevaFin.isAfter(nuevaInicio)) return [];

    final List<String> alumnosAfectados = switch (_tipoAsignacion) {
      TipoAsignacion.individual =>
        _alumnoSeleccionadoId != null ? [_alumnoSeleccionadoId!] : [],
      TipoAsignacion.grupal ||
      TipoAsignacion.recurrente => _alumnosGrupalesIds.toList(),
    };

    if (alumnosAfectados.isEmpty) return [];

    final tareasDelDia = widget.tareas.where(
      (t) =>
          t.id != _tareaEnEdicion?.id &&
          t.fecha.year == _fechaSeleccionada.year &&
          t.fecha.month == _fechaSeleccionada.month &&
          t.fecha.day == _fechaSeleccionada.day,
    );

    final List<Tarea> enConflicto = [];

    for (final tarea in tareasDelDia) {
      final comparteAlumno = tarea.alumnoIds.any(
        (id) => alumnosAfectados.contains(id),
      );
      if (!comparteAlumno) continue;

      final solapa =
          nuevaInicio.isBefore(tarea.horaFinal) &&
          nuevaFin.isAfter(tarea.horaInicio);
      if (solapa) {
        enConflicto.add(tarea);
      }
    }

    return enConflicto;
  }

  InputDecoration _deco(
    AppPalette p,
    String etiqueta, {
    String? hint,
    IconData? icono,
    bool compacto = false,
  }) => InputDecoration(
    labelText: etiqueta,
    labelStyle: const TextStyle(fontSize: 16),
    hintText: hint,
    prefixIcon: icono == null ? null : Icon(icono, size: 26),
    filled: true,
    fillColor: p.background,
    isDense: compacto,
    contentPadding: EdgeInsets.symmetric(
      horizontal: 16,
      vertical: compacto ? 12 : 18,
    ),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
  );

  ButtonStyle get _estiloSecundario => OutlinedButton.styleFrom(
    minimumSize: const Size(0, 54),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
  );

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final solapamientos = _obtenerSolapamientos();

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        title: Text(
          'Planificador y Asignación de Tareas',
          style: TextStyle(color: p.primary, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.print_outlined, color: p.primary, size: 28),
            tooltip: 'Exportar/Imprimir',
            onPressed: () => _exportar(imprimir: true),
          ),
          IconButton(
            icon: Icon(
              Icons.picture_as_pdf_outlined,
              color: p.primary,
              size: 28,
            ),
            tooltip: 'Guardar PDF',
            onPressed: () => _exportar(imprimir: false),
          ),
          IconButton(
            icon: Icon(
              Icons.calendar_today_outlined,
              color: p.primary,
              size: 28,
            ),
            tooltip: 'Cambiar fecha',
            onPressed: _seleccionarFecha,
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${_fechaSeleccionada.day.toString().padLeft(2, '0')}/${_fechaSeleccionada.month.toString().padLeft(2, '0')}/${_fechaSeleccionada.year}',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: p.textDark,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 5, child: _buildCronogramaPanel()),
              const SizedBox(width: 12),
              Expanded(
                flex: 6,
                child: _buildFormularioAsignacion(solapamientos),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCronogramaPanel() {
    final p = context.palette;
    final textoFiltroAula = _filtroAulaCtrl.text.trim().toLowerCase();

    final tareasDelDia = widget.tareas.where((t) {
      final mismaFecha =
          t.fecha.year == _fechaSeleccionada.year &&
          t.fecha.month == _fechaSeleccionada.month &&
          t.fecha.day == _fechaSeleccionada.day;
      if (!mismaFecha) return false;

      if (_filtroAlumnoId != null && !t.alumnoIds.contains(_filtroAlumnoId)) {
        return false;
      }

      if (textoFiltroAula.isNotEmpty) {
        final aulaTarea = t.aulaId.trim().toLowerCase();
        if (!aulaTarea.contains(textoFiltroAula)) {
          return false;
        }
      }

      return true;
    }).toList()..sort((a, b) => a.horaInicio.compareTo(b.horaInicio));

    final hoy = DateTime.now();
    final esHoy =
        _fechaSeleccionada.year == hoy.year &&
        _fechaSeleccionada.month == hoy.month &&
        _fechaSeleccionada.day == hoy.day;

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Jornada Escolar',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: p.textDark,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 220,
                child: TextField(
                  controller: _filtroAulaCtrl,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Buscar aula...',
                    prefixIcon: Icon(Icons.search, color: p.textSoft),
                    suffixIcon: _filtroAulaCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              setState(() {
                                _filtroAulaCtrl.clear();
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: p.background,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {});
                  },
                ),
              ),
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: p.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: DropdownButton<String?>(
                  value: _filtroAlumnoId,
                  underline: const SizedBox(),
                  hint: const Text(
                    'Todos los alumnos',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: p.textDark,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Todos los alumnos'),
                    ),
                    ...widget.alumnos.map(
                      (a) => DropdownMenuItem<String?>(
                        value: a.id,
                        child: Text(a.nombre),
                      ),
                    ),
                  ],
                  onChanged: (val) => setState(() => _filtroAlumnoId = val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ---- Selector de día ----
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: p.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left, color: p.primary, size: 30),
                  tooltip: 'Día anterior',
                  onPressed: () => _cambiarDia(-1),
                ),
                Expanded(
                  child: InkWell(
                    onTap: _seleccionarFecha,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_month,
                            color: p.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_fechaSeleccionada.day.toString().padLeft(2, '0')}/${_fechaSeleccionada.month.toString().padLeft(2, '0')}/${_fechaSeleccionada.year}',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: p.textDark,
                              fontSize: 19,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right, color: p.primary, size: 30),
                  tooltip: 'Día siguiente',
                  onPressed: () => _cambiarDia(1),
                ),
                if (!esHoy)
                  TextButton(
                    onPressed: () {
                      final fechaActual = DateTime.now();
                      setState(() => _fechaSeleccionada = fechaActual);
                      if (widget.onFechaCambiada != null) {
                        widget.onFechaCambiada!(fechaActual);
                      }
                    },
                    child: const Text(
                      'Hoy',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: tareasDelDia.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_available,
                          size: 60,
                          color: p.textSoft,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'No hay tareas asignadas con estos filtros.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 17, color: p.textSoft),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: tareasDelDia.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final tarea = tareasDelDia[index];
                      final esSeleccionada = _tareaEnEdicion?.id == tarea.id;
                      final horaStr =
                          '${tarea.horaInicio.hour.toString().padLeft(2, '0')}:${tarea.horaInicio.minute.toString().padLeft(2, '0')} - ${tarea.horaFinal.hour.toString().padLeft(2, '0')}:${tarea.horaFinal.minute.toString().padLeft(2, '0')}';

                      return InkWell(
                        onTap: () => _cargarTareaParaEdicion(tarea),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: esSeleccionada ? p.cardTint : p.background,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: esSeleccionada
                                  ? p.primary
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: p.primary,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Text(
                                            horaStr,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        // Iconos indicadores de recursos adjuntos
                                        if (tarea.audioUrl != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 6,
                                            ),
                                            child: Icon(
                                              Icons.audiotrack,
                                              size: 20,
                                              color: p.primary,
                                            ),
                                          ),
                                        if (tarea.videoUrl != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 6,
                                            ),
                                            child: Icon(
                                              Icons.videocam,
                                              size: 20,
                                              color: p.primary,
                                            ),
                                          ),
                                        if (tarea.enlaceWeb != null &&
                                            tarea.enlaceWeb!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 6,
                                            ),
                                            child: Icon(
                                              Icons.link,
                                              size: 20,
                                              color: p.primary,
                                            ),
                                          ),
                                        if (tarea.pasos.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 6,
                                            ),
                                            child: Tooltip(
                                              message:
                                                  '${tarea.pasos.length} paso(s)',
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.checklist,
                                                    size: 20,
                                                    color: p.primary,
                                                  ),
                                                  Text(
                                                    '${tarea.pasos.length}',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: p.primary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      tarea.nombre,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 19,
                                        color: p.textDark,
                                      ),
                                    ),
                                    if (tarea.descripcion.isNotEmpty)
                                      Text(
                                        tarea.descripcion,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: p.textSoft,
                                          fontSize: 15,
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Alumnos: ${tarea.alumnoIds.length} asignados | Aula: ${tarea.aulaId.isEmpty ? 'Sin aula' : tarea.aulaId}',
                                      style: TextStyle(
                                        color: p.textSoft,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Builder(
                                      builder: (_) {
                                        final ids = _filtroAlumnoId != null
                                            ? [_filtroAlumnoId!]
                                            : tarea.alumnoIds;
                                        final hechos = ids
                                            .where(tarea.estaCompletadaPor)
                                            .length;
                                        final todas =
                                            ids.isNotEmpty &&
                                            hechos == ids.length;
                                        return Row(
                                          children: [
                                            Icon(
                                              todas
                                                  ? Icons.check_circle
                                                  : Icons
                                                        .radio_button_unchecked,
                                              size: 20,
                                              color: todas
                                                  ? p.greenDark
                                                  : p.textSoft,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              todas
                                                  ? 'Completada'
                                                  : hechos > 0
                                                  ? 'Completada por $hechos de ${ids.length}'
                                                  : 'Pendiente',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                                color: todas
                                                    ? p.greenDark
                                                    : p.textSoft,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                  size: 28,
                                ),
                                tooltip: 'Eliminar tarea',
                                onPressed: () => _confirmarEliminacion(tarea),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormularioAsignacion(List<Tarea> solapamientos) {
    final p = context.palette;
    final hayConflicto = solapamientos.isNotEmpty;
    final esEdicion = _tareaEnEdicion != null;

    Widget etiqueta(String texto) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: p.textDark,
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    esEdicion ? 'Editar Tarea' : 'Planificar Nueva Tarea',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: p.textDark,
                    ),
                  ),
                  if (esEdicion)
                    TextButton.icon(
                      icon: const Icon(Icons.cancel_outlined, size: 22),
                      label: const Text(
                        'Cancelar edición',
                        style: TextStyle(fontSize: 16),
                      ),
                      onPressed: _limpiarFormulario,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              etiqueta('Modalidad de Asignación:'),
              SegmentedButton<TipoAsignacion>(
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: p.primary,
                  selectedForegroundColor: Colors.white,
                ),
                segments: const [
                  ButtonSegment(
                    value: TipoAsignacion.individual,
                    label: Text('Individual'),
                    icon: Icon(Icons.person_outline),
                  ),
                  ButtonSegment(
                    value: TipoAsignacion.grupal,
                    label: Text('Grupal'),
                    icon: Icon(Icons.groups_outlined),
                  ),
                  ButtonSegment(
                    value: TipoAsignacion.recurrente,
                    label: Text('Recurrente'),
                    icon: Icon(Icons.repeat),
                  ),
                ],
                selected: {_tipoAsignacion},
                onSelectionChanged: (val) {
                  setState(() {
                    _tipoAsignacion = val.first;
                    _alumnoSeleccionadoId = null;
                    _alumnosGrupalesIds.clear();
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildSelectorAlumnos(),
              const SizedBox(height: 16),
              if (_tipoAsignacion == TipoAsignacion.recurrente) ...[
                etiqueta('Frecuencia de repetición:'),
                DropdownButtonFormField<FrecuenciaRecurrencia>(
                  initialValue: _frecuencia,
                  style: TextStyle(fontSize: 17, color: p.textDark),
                  decoration: _deco(p, '', compacto: true),
                  items: const [
                    DropdownMenuItem(
                      value: FrecuenciaRecurrencia.diario,
                      child: Text('Diario (Todos los días)'),
                    ),
                    DropdownMenuItem(
                      value: FrecuenciaRecurrencia.diasLectivos,
                      child: Text('Días lectivos (Lunes a Viernes)'),
                    ),
                    DropdownMenuItem(
                      value: FrecuenciaRecurrencia.semanal,
                      child: Text('Semanal (Mismo día cada semana)'),
                    ),
                  ],
                  onChanged: (val) => setState(() => _frecuencia = val!),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _nombreCtrl,
                style: const TextStyle(fontSize: 18),
                decoration: _deco(
                  p,
                  'Nombre de la tarea *',
                  hint: 'Ej. Lectura compartida, Taller de Plástica',
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Ingresa el nombre de la tarea'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                style: const TextStyle(fontSize: 17),
                decoration: _deco(p, 'Descripción / Instrucciones'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _aulaCtrl,
                style: const TextStyle(fontSize: 17),
                decoration: _deco(
                  p,
                  'Aula / Espacio escolar',
                  hint: 'Ej. Aula TEA, Gimnasio, Aula 3',
                  icono: Icons.room_outlined,
                ),
              ),
              const SizedBox(height: 20),

              // ---- SECCIÓN MULTIMEDIA (HU 08.2) ----
              etiqueta('Recursos Multimedia (Opcional):'),
              TextFormField(
                controller: _enlaceWebCtrl,
                style: const TextStyle(fontSize: 17),
                decoration: _deco(
                  p,
                  'Enlace web (YouTube, Drive, recurso externo...)',
                  hint: 'https://...',
                  icono: Icons.link,
                ),
              ),
              const SizedBox(height: 10),
              if (widget.subiendoMultimedia)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      const LinearProgressIndicator(),
                      const SizedBox(height: 6),
                      Text(
                        'Subiendo archivo a Firebase...',
                        style: TextStyle(fontSize: 14, color: p.textSoft),
                      ),
                    ],
                  ),
                )
              else
                Row(
                  children: [
                    // Botón Audio + Botón de quitar si ya existe
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: _estiloSecundario,
                              icon: Icon(
                                _audioUrl != null
                                    ? Icons.check_circle
                                    : Icons.audiotrack,
                                color: _audioUrl != null
                                    ? p.greenDark
                                    : p.primary,
                              ),
                              label: Text(
                                _audioUrl != null
                                    ? 'Audio listo'
                                    : 'Subir Audio',
                                overflow: TextOverflow.ellipsis,
                              ),
                              onPressed: () async {
                                if (widget.onSubirAudio != null) {
                                  final url = await widget.onSubirAudio!();
                                  if (!mounted) return;
                                  if (url != null) {
                                    setState(() => _audioUrl = url);
                                  }
                                }
                              },
                            ),
                          ),
                          if (_audioUrl != null)
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.redAccent,
                                size: 24,
                              ),
                              tooltip: 'Quitar audio',
                              onPressed: () => setState(() => _audioUrl = null),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Botón Vídeo + Botón de quitar si ya existe
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: _estiloSecundario,
                              icon: Icon(
                                _videoUrl != null
                                    ? Icons.check_circle
                                    : Icons.video_library,
                                color: _videoUrl != null
                                    ? p.greenDark
                                    : p.primary,
                              ),
                              label: Text(
                                _videoUrl != null
                                    ? 'Vídeo listo'
                                    : 'Subir Vídeo',
                                overflow: TextOverflow.ellipsis,
                              ),
                              onPressed: () async {
                                if (widget.onSubirVideo != null) {
                                  final url = await widget.onSubirVideo!();
                                  if (!mounted) return;
                                  if (url != null) {
                                    setState(() => _videoUrl = url);
                                  }
                                }
                              },
                            ),
                          ),
                          if (_videoUrl != null)
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.redAccent,
                                size: 24,
                              ),
                              tooltip: 'Quitar vídeo',
                              onPressed: () => setState(() => _videoUrl = null),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),

              // ---- LISTA DE VERIFICACIÓN / PASOS (HU 09) ----
              _buildSeccionPasos(),
              const SizedBox(height: 20),

              // ---- HORARIO ESCOLAR ----
              etiqueta('Horario Escolar:'),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: _estiloSecundario,
                      icon: const Icon(Icons.access_time),
                      label: Text('Inicio: ${_horaInicio.format(context)}'),
                      onPressed: () => _seleccionarHora(esInicio: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: _estiloSecundario,
                      icon: const Icon(Icons.access_time_filled),
                      label: Text('Fin: ${_horaFin.format(context)}'),
                      onPressed: () => _seleccionarHora(esInicio: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (hayConflicto)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: p.orangeSoft,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: p.orange, width: 2),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: p.orange,
                        size: 32,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Solapamiento detectado',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: p.orange,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Existe conflicto con ${solapamientos.length} tarea(s) en este horario: "${solapamientos.first.nombre}". Modifica la hora o los alumnos asignados para evitar cruces.',
                              style: TextStyle(fontSize: 15, color: p.textDark),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: p.greenSoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: p.greenDark,
                        size: 26,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Horario escolar libre de solapamientos.',
                          style: TextStyle(
                            color: p.greenDark,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  icon: _guardando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Icon(esEdicion ? Icons.edit : Icons.save_outlined),
                  label: Text(
                    _guardando
                        ? 'Guardando...'
                        : (esEdicion ? 'Guardar Cambios' : 'Asignar Tarea'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hayConflicto || widget.subiendoMultimedia
                        ? Colors.grey
                        : p.primary,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed:
                      hayConflicto || _guardando || widget.subiendoMultimedia
                      ? null
                      : _ejecutarGuardado,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeccionPasos() {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lista de verificación / Paso a paso (Opcional):',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: p.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _nuevoPasoCtrl,
                style: const TextStyle(fontSize: 17),
                decoration: _deco(
                  p,
                  'Añadir paso...',
                  hint: 'Ej. Sacar el cuaderno de la mochila',
                  compacto: true,
                ),
                onSubmitted: (_) => _agregarPaso(),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              style: _estiloSecundario,
              icon: const Icon(Icons.add),
              label: const Text('Añadir'),
              onPressed: _agregarPaso,
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_pasos.isEmpty)
          Text(
            'Sin pasos. Añade pasos y ordénalos para guiar al alumno.',
            style: TextStyle(fontSize: 15, color: p.textSoft),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: _pasos.length,
            onReorderItem: _reordenarPasos,
            itemBuilder: (context, index) {
              final paso = _pasos[index];
              return Container(
                key: ValueKey(paso.id),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: p.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: p.primary,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        paso.descripcion,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: p.textDark,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_upward, size: 22),
                      tooltip: 'Subir paso',
                      onPressed: index == 0
                          ? null
                          : () => _moverPaso(index, -1),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_downward, size: 22),
                      tooltip: 'Bajar paso',
                      onPressed: index == _pasos.length - 1
                          ? null
                          : () => _moverPaso(index, 1),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 22),
                      tooltip: 'Editar paso',
                      onPressed: () => _editarPaso(index),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 22,
                        color: Colors.redAccent,
                      ),
                      tooltip: 'Eliminar paso',
                      onPressed: () => _eliminarPaso(index),
                    ),
                    ReorderableDragStartListener(
                      index: index,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(Icons.drag_handle, color: p.textSoft),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildSelectorAlumnos() {
    final p = context.palette;

    if (widget.alumnos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.cardTint,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'No hay alumnos cargados en la base de datos.',
          style: TextStyle(color: p.textSoft, fontSize: 15),
        ),
      );
    }

    if (_tipoAsignacion == TipoAsignacion.individual) {
      return DropdownButtonFormField<String>(
        initialValue: _alumnoSeleccionadoId,
        style: TextStyle(fontSize: 18, color: p.textDark),
        decoration: _deco(p, 'Selecciona al Alumno *'),
        items: widget.alumnos
            .map((a) => DropdownMenuItem(value: a.id, child: Text(a.nombre)))
            .toList(),
        onChanged: (val) => setState(() => _alumnoSeleccionadoId = val),
        validator: (val) => val == null ? 'Debes seleccionar un alumno' : null,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Seleccionar Alumnos del Grupo:',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: p.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: widget.alumnos.map((a) {
            final seleccionado = _alumnosGrupalesIds.contains(a.id);
            return FilterChip(
              label: Text(a.nombre),
              labelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              selectedColor: p.badge,
              selected: seleccionado,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _alumnosGrupalesIds.add(a.id);
                  } else {
                    _alumnosGrupalesIds.remove(a.id);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _seleccionarFecha() async {
    final pick = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pick != null) {
      setState(() => _fechaSeleccionada = pick);

      if (widget.onFechaCambiada != null) {
        widget.onFechaCambiada!(pick);
      }
    }
  }

  Future<void> _seleccionarHora({required bool esInicio}) async {
    final pick = await showTimePicker(
      context: context,
      initialTime: esInicio ? _horaInicio : _horaFin,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (pick != null) {
      setState(() {
        if (esInicio) {
          _horaInicio = pick;
        } else {
          _horaFin = pick;
        }
      });
    }
  }

  Future<void> _confirmarEliminacion(Tarea tarea) async {
    final bool esFiltroEspecifico = _filtroAlumnoId != null;

    String nombreAlumno = '';
    if (esFiltroEspecifico) {
      final alumno = widget.alumnos.firstWhere(
        (a) => a.id == _filtroAlumnoId,
        orElse: () => Usuario(
          id: '',
          nombreUsuario: '',
          nombre: 'el alumno',
          rol: RolUsuario.alumno,
        ),
      );
      nombreAlumno = alumno.nombre;
    }

    final String tituloDialogo = esFiltroEspecifico
        ? 'Desasignar Tarea'
        : 'Eliminar Tarea';
    final String contenidoDialogo = esFiltroEspecifico
        ? '¿Seguro que deseas quitar la tarea "${tarea.nombre}" a $nombreAlumno?'
        : '¿Seguro que deseas eliminar la tarea "${tarea.nombre}" por completo para todos los alumnos?';

    final bool? del = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tituloDialogo),
        content: Text(contenidoDialogo),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            child: Text(
              esFiltroEspecifico ? 'Desasignar' : 'Eliminar',
              style: const TextStyle(color: Colors.red),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (del == true) {
      if (esFiltroEspecifico) {
        final nuevosAlumnoIds = tarea.alumnoIds
            .where((id) => id != _filtroAlumnoId)
            .toList();

        if (nuevosAlumnoIds.isEmpty) {
          if (widget.onEliminarTarea != null) {
            await widget.onEliminarTarea!(tarea.id);
          }
        } else {
          if (widget.onActualizarTarea != null) {
            final tareaActualizada = tarea.copyWith(alumnoIds: nuevosAlumnoIds);
            await widget.onActualizarTarea!(tareaActualizada);
          }
        }
      } else {
        if (widget.onEliminarTarea != null) {
          await widget.onEliminarTarea!(tarea.id);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              esFiltroEspecifico
                  ? 'Tarea desasignada a $nombreAlumno correctamente.'
                  : 'Tarea eliminada correctamente.',
            ),
          ),
        );
        if (_tareaEnEdicion?.id == tarea.id) {
          _limpiarFormulario();
        }
      }
    }
  }

  Future<void> _ejecutarGuardado() async {
    if (!_formKey.currentState!.validate()) return;

    final List<String> alumnosAsignados = switch (_tipoAsignacion) {
      TipoAsignacion.individual =>
        _alumnoSeleccionadoId != null ? [_alumnoSeleccionadoId!] : [],
      TipoAsignacion.grupal ||
      TipoAsignacion.recurrente => _alumnosGrupalesIds.toList(),
    };

    if (alumnosAsignados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos un alumno para la tarea.'),
        ),
      );
      return;
    }

    final inicio = _combinarFechaYHora(_fechaSeleccionada, _horaInicio);
    final fin = _combinarFechaYHora(_fechaSeleccionada, _horaFin);

    if (!fin.isAfter(inicio)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La hora final debe ser posterior a la hora de inicio.',
          ),
        ),
      );
      return;
    }

    final esEdicion = _tareaEnEdicion != null;
    final enlaceTexto = _enlaceWebCtrl.text.trim();

    final tareaAGuardar = Tarea(
      id: esEdicion ? _tareaEnEdicion!.id : '',
      nombre: _nombreCtrl.text.trim(),
      descripcion: _descCtrl.text.trim(),
      fecha: _fechaSeleccionada,
      horario: inicio.hour < 14 ? 'mañana' : 'tarde',
      horaInicio: inicio,
      horaFinal: fin,
      aulaId: _aulaCtrl.text.trim(),
      creadaPor: widget.profesorId,
      alumnoIds: alumnosAsignados,
      pasos: _renumerarPasos(_pasos),
      contingenciaIds: esEdicion ? _tareaEnEdicion!.contingenciaIds : const [],
      completadaPor: esEdicion ? _tareaEnEdicion!.completadaPor : const {},
      pictogramas: esEdicion ? _tareaEnEdicion!.pictogramas : const [],
      imagenAdjuntaUrl: esEdicion ? _tareaEnEdicion!.imagenAdjuntaUrl : null,
      audioUrl: _audioUrl,
      videoUrl: _videoUrl,
      enlaceWeb: enlaceTexto.isEmpty ? null : enlaceTexto,
    );

    setState(() => _guardando = true);
    try {
      if (esEdicion) {
        if (widget.onActualizarTarea != null) {
          await widget.onActualizarTarea!(tareaAGuardar);
        }
      } else {
        if (widget.onGuardarTarea != null) {
          await widget.onGuardarTarea!(
            tareaAGuardar,
            _tipoAsignacion,
            _tipoAsignacion == TipoAsignacion.recurrente ? _frecuencia : null,
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              esEdicion
                  ? 'Tarea actualizada correctamente.'
                  : 'Tarea planificada correctamente.',
            ),
          ),
        );
        _limpiarFormulario();
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }
}

class _EditarPasoDialog extends StatefulWidget {
  const _EditarPasoDialog({required this.descripcionInicial});

  final String descripcionInicial;

  @override
  State<_EditarPasoDialog> createState() => _EditarPasoDialogState();
}

class _EditarPasoDialogState extends State<_EditarPasoDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.descripcionInicial);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _guardar() {
    final texto = _ctrl.text.trim();
    if (texto.isEmpty) return;
    Navigator.of(context).pop(texto);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AlertDialog(
      backgroundColor: p.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'Editar paso',
        style: TextStyle(fontWeight: FontWeight.w800, color: p.textDark),
      ),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        style: const TextStyle(fontSize: 18),
        decoration: InputDecoration(
          labelText: 'Descripción del paso',
          filled: true,
          fillColor: p.background,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onSubmitted: (_) => _guardar(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
        ),
        FilledButton(
          onPressed: _guardar,
          style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
          child: const Text('Guardar', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}
