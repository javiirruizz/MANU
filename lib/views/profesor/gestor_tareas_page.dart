import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../models/tarea.dart';
import '../../models/usuario.dart';

enum TipoAsignacion { individual, grupal, recurrente }

enum FrecuenciaRecurrencia { diario, semanal, diasLectivos }

/// Pantalla del Gestor de Planificación y Asignación de Tareas (HU 07).
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
  });

  final List<Usuario> alumnos;
  final List<Tarea> tareas;
  final List<String> aulas;
  final String profesorId;

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

  TipoAsignacion _tipoAsignacion = TipoAsignacion.individual;
  FrecuenciaRecurrencia _frecuencia = FrecuenciaRecurrencia.semanal;

  String? _alumnoSeleccionadoId;
  final Set<String> _alumnosGrupalesIds = {};

  TimeOfDay _horaInicio = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _horaFin = const TimeOfDay(hour: 10, minute: 0);

  bool _guardando = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    _aulaCtrl.dispose();
    _filtroAulaCtrl.dispose();
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
    setState(() {
      _tareaEnEdicion = null;
      _alumnoSeleccionadoId = null;
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

  @override
  Widget build(BuildContext context) {
    final solapamientos = _obtenerSolapamientos();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Planificador y Asignación de Tareas',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.calendar_today_outlined,
              color: AppColors.primary,
            ),
            tooltip: 'Cambiar fecha',
            onPressed: _seleccionarFecha,
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${_fechaSeleccionada.day.toString().padLeft(2, '0')}/${_fechaSeleccionada.month.toString().padLeft(2, '0')}/${_fechaSeleccionada.year}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 5, child: _buildCronogramaPanel()),
              const SizedBox(width: 16),
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
    final textoFiltroAula = _filtroAulaCtrl.text.trim().toLowerCase();

    // Filtrado de tareas (Fecha + Alumno + Texto de Aula/Lugar)
    final tareasDelDia = widget.tareas.where((t) {
      final mismaFecha =
          t.fecha.year == _fechaSeleccionada.year &&
          t.fecha.month == _fechaSeleccionada.month &&
          t.fecha.day == _fechaSeleccionada.day;
      if (!mismaFecha) return false;

      // Filtro por Alumno
      if (_filtroAlumnoId != null && !t.alumnoIds.contains(_filtroAlumnoId)) {
        return false;
      }

      // Filtro por Texto de Aula / Lugar (Búsqueda flexible insensible a mayúsculas)
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado: Título y Filtros (Buscador de Aula + Dropdown de Alumnos)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Jornada Escolar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              Row(
                children: [
                  // CAMPO DE TEXTO PARA FILTRAR POR AULA / LUGAR
                  SizedBox(
                    width: 160,
                    height: 38,
                    child: TextField(
                      controller: _filtroAulaCtrl,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Buscar aula...',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSoft,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          size: 18,
                          color: AppColors.textSoft,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon: _filtroAulaCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  setState(() {
                                    _filtroAulaCtrl.clear();
                                  });
                                },
                              )
                            : null,
                      ),
                      onChanged: (val) {
                        setState(() {}); // Redibuja el cronograma al escribir
                      },
                    ),
                  ),
                  const SizedBox(width: 8),

                  // FILTRO DE ALUMNOS
                  DropdownButton<String?>(
                    value: _filtroAlumnoId,
                    underline: const SizedBox(),
                    hint: const Text(
                      'Todos los alumnos',
                      style: TextStyle(fontSize: 13),
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textDark,
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
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // BARRA DE NAVEGACIÓN DE FECHA
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.chevron_left,
                    color: AppColors.primary,
                  ),
                  tooltip: 'Día anterior',
                  onPressed: () => _cambiarDia(-1),
                ),
                InkWell(
                  onTap: _seleccionarFecha,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_fechaSeleccionada.day.toString().padLeft(2, '0')}/${_fechaSeleccionada.month.toString().padLeft(2, '0')}/${_fechaSeleccionada.year}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.chevron_right,
                    color: AppColors.primary,
                  ),
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
                    child: const Text('Hoy'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // LISTA DE TAREAS DEL DÍA
          Expanded(
            child: tareasDelDia.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.event_available,
                          size: 50,
                          color: AppColors.textSoft,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No hay tareas asignadas con estos filtros.',
                          style: TextStyle(color: AppColors.textSoft),
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
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: esSeleccionada
                                ? AppColors.primary.withAlpha(20)
                                : AppColors.cardBlue,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: esSeleccionada
                                  ? AppColors.primary
                                  : AppColors.primary.withAlpha(50),
                              width: esSeleccionada ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  horaStr,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tarea.nombre,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    if (tarea.descripcion.isNotEmpty)
                                      Text(
                                        tarea.descripcion,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.textSoft,
                                          fontSize: 13,
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Alumnos: ${tarea.alumnoIds.length} asignados | Aula: ${tarea.aulaId.isEmpty ? 'Sin aula' : tarea.aulaId}',
                                      style: const TextStyle(
                                        color: AppColors.textSoft,
                                        fontSize: 12,
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
                                              size: 16,
                                              color: todas
                                                  ? AppColors.greenDark
                                                  : AppColors.textSoft,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              todas
                                                  ? 'Completada'
                                                  : hechos > 0
                                                  ? 'Completada por $hechos de ${ids.length}'
                                                  : 'Pendiente',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: todas
                                                    ? AppColors.greenDark
                                                    : AppColors.textSoft,
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
    final hayConflicto = solapamientos.isNotEmpty;
    final esEdicion = _tareaEnEdicion != null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
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
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  if (esEdicion)
                    TextButton.icon(
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text('Cancelar edición'),
                      onPressed: _limpiarFormulario,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Modalidad de Asignación:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SegmentedButton<TipoAsignacion>(
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
                const Text(
                  'Frecuencia de repetición:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<FrecuenciaRecurrencia>(
                  initialValue: _frecuencia,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
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
                decoration: InputDecoration(
                  labelText: 'Nombre de la tarea *',
                  hintText: 'Ej. Lectura compartida, Taller de Plástica',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Ingresa el nombre de la tarea'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Descripción / Instrucciones',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _aulaCtrl,
                decoration: InputDecoration(
                  labelText: 'Aula / Espacio escolar',
                  hintText: 'Ej. Aula TEA, Gimnasio, Aula 3',
                  prefixIcon: const Icon(Icons.room_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Horario Escolar:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time),
                      label: Text('Inicio: ${_horaInicio.format(context)}'),
                      onPressed: () => _seleccionarHora(esInicio: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.orangeSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.orange),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.orange,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Solapamiento detectado',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.orange,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Existe conflicto con ${solapamientos.length} tarea(s) en este horario: "${solapamientos.first.nombre}". Modifica la hora o los alumnos asignados para evitar cruces.',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textDark,
                              ),
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
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.greenSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.check_circle_outline,
                        color: AppColors.greenDark,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Horario escolar libre de solapamientos.',
                        style: TextStyle(
                          color: AppColors.greenDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  icon: _guardando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
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
                    backgroundColor: hayConflicto
                        ? Colors.grey
                        : AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: hayConflicto || _guardando
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

  Widget _buildSelectorAlumnos() {
    if (widget.alumnos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.chip,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'No hay alumnos cargados en la base de datos.',
          style: TextStyle(color: AppColors.textSoft, fontSize: 13),
        ),
      );
    }

    if (_tipoAsignacion == TipoAsignacion.individual) {
      return DropdownButtonFormField<String>(
        initialValue: _alumnoSeleccionadoId,
        decoration: InputDecoration(
          labelText: 'Selecciona al Alumno *',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
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
        const Text(
          'Seleccionar Alumnos del Grupo:',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: widget.alumnos.map((a) {
            final seleccionado = _alumnosGrupalesIds.contains(a.id);
            return FilterChip(
              label: Text(a.nombre),
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

      // Añade estas líneas para avisar al ViewModel del cambio de fecha
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

    // Obtener el nombre del alumno seleccionado para mostrarlo en el diálogo
    String nombreAlumno = '';
    if (esFiltroEspecifico) {
      final alumno = widget.alumnos.firstWhere(
        (a) => a.id == _filtroAlumnoId,
        orElse: () => Usuario(
          id: '',
          nombreUsuario: '',
          nombre: 'el  alumno',
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
