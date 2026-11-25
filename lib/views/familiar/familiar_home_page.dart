import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../data/tarea_repository.dart';
import '../../data/usuario_repository.dart';
import '../../models/tarea.dart';
import '../../models/usuario.dart';
import '../../viewmodels/auth_view_model.dart';

/// Pantalla principal del rol Familiar (HU 34: gestión de tareas domésticas).
class FamiliarHomePage extends StatefulWidget {
  const FamiliarHomePage({super.key});

  @override
  State<FamiliarHomePage> createState() => _FamiliarHomePageState();
}

class _FamiliarHomePageState extends State<FamiliarHomePage> {
  final _tareaRepo = TareaRepository();
  final _usuarioRepo = UsuarioRepository();

  List<Usuario> _alumnosAsignados = [];
  String? _alumnoSeleccionadoId;
  bool _cargandoAlumnos = true;
  DateTime _fechaSeleccionada = DateTime.now();

  @override
  void initState() {
    super.initState();
    _cargarAlumnosAsignados();
  }

  Future<void> _cargarAlumnosAsignados() async {
    final familiar = context.read<AuthViewModel>().usuario!;
    if (familiar.alumnoIds.isEmpty) {
      if (mounted) {
        setState(() {
          _alumnosAsignados = [];
          _cargandoAlumnos = false;
        });
      }
      return;
    }

    final todos = await _usuarioRepo.getAlumnos();
    final filtrados = todos
        .where((a) => familiar.alumnoIds.contains(a.id))
        .toList();

    if (!mounted) return;
    setState(() {
      _alumnosAsignados = filtrados;
      if (filtrados.isNotEmpty) {
        _alumnoSeleccionadoId = filtrados.first.id;
      }
      _cargandoAlumnos = false;
    });
  }

  void _cambiarDia(int dias) {
    setState(() {
      _fechaSeleccionada = _fechaSeleccionada.add(Duration(days: dias));
    });
  }

  Future<void> _seleccionarFecha() async {
    final pick = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime.now().subtract(const Duration(days: 60)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pick != null && mounted) {
      setState(() => _fechaSeleccionada = pick);
    }
  }

  Future<void> _abrirFormularioTarea({
    required Usuario familiar,
    required String alumnoId,
    Tarea? tareaExistente,
  }) async {
    final esEdicion = tareaExistente != null;

    if (esEdicion && tareaExistente.creadaPor != familiar.id) {
      return;
    }

    final nombreCtrl = TextEditingController(
      text: tareaExistente?.nombre ?? '',
    );
    final descCtrl = TextEditingController(
      text: tareaExistente?.descripcion ?? '',
    );

    TimeOfDay horaInicio = tareaExistente != null
        ? TimeOfDay.fromDateTime(tareaExistente.horaInicio)
        : const TimeOfDay(hour: 17, minute: 0);
    TimeOfDay horaFin = tareaExistente != null
        ? TimeOfDay.fromDateTime(tareaExistente.horaFinal)
        : const TimeOfDay(hour: 17, minute: 30);

    const sugerenciasCasa = [
      'Hacer la cama',
      'Lavarse los dientes',
      'Preparar la mochila',
      'Recoger la habitación',
    ];

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Future<void> elegirHora(bool esInicio) async {
            final pick = await showTimePicker(
              context: ctx,
              initialTime: esInicio ? horaInicio : horaFin,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(alwaysUse24HourFormat: true),
                child: child!,
              ),
            );
            if (pick != null) {
              setDialogState(() {
                if (esInicio) {
                  horaInicio = pick;
                } else {
                  horaFin = pick;
                }
              });
            }
          }

          return AlertDialog(
            title: Text(
              esEdicion
                  ? 'Editar tarea familiar'
                  : 'Nueva tarea doméstica / en casa',
            ),
            content: SizedBox(
              width: 460,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!esEdicion) ...[
                      const Text(
                        'Sugerencias rápidas:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: sugerenciasCasa
                            .map(
                              (s) => ActionChip(
                                label: Text(s),
                                onPressed: () =>
                                    setDialogState(() => nombreCtrl.text = s),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: nombreCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la tarea *',
                        hintText: 'Ej. Hacer la cama',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Indicaciones (opcional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Horario:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.access_time),
                            label: Text(
                              'Inicio: ${horaInicio.hour.toString().padLeft(2, '0')}:${horaInicio.minute.toString().padLeft(2, '0')}',
                            ),
                            onPressed: () => elegirHora(true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.access_time_filled),
                            label: Text(
                              'Fin: ${horaFin.hour.toString().padLeft(2, '0')}:${horaFin.minute.toString().padLeft(2, '0')}',
                            ),
                            onPressed: () => elegirHora(false),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.save),
                label: Text(esEdicion ? 'Guardar cambios' : 'Crear tarea'),
                onPressed: () async {
                  final nombre = nombreCtrl.text.trim();
                  if (nombre.isEmpty) return;

                  final fechaBase = esEdicion
                      ? tareaExistente.fecha
                      : _fechaSeleccionada;
                  final inicio = DateTime(
                    fechaBase.year,
                    fechaBase.month,
                    fechaBase.day,
                    horaInicio.hour,
                    horaInicio.minute,
                  );
                  final fin = DateTime(
                    fechaBase.year,
                    fechaBase.month,
                    fechaBase.day,
                    horaFin.hour,
                    horaFin.minute,
                  );

                  if (!fin.isAfter(inicio)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'La hora de fin debe ser posterior a la de inicio.',
                        ),
                      ),
                    );
                    return;
                  }

                  final horarioStr = inicio.hour < 14 ? 'mañana' : 'tarde';

                  if (esEdicion) {
                    final actualizada = tareaExistente.copyWith(
                      nombre: nombre,
                      descripcion: descCtrl.text.trim(),
                      horario: horarioStr,
                      horaInicio: inicio,
                      horaFinal: fin,
                    );
                    await _tareaRepo.actualizarTarea(actualizada);
                  } else {
                    final nueva = Tarea(
                      id: '',
                      nombre: nombre,
                      descripcion: descCtrl.text.trim(),
                      fecha: fechaBase,
                      horario: horarioStr,
                      horaInicio: inicio,
                      horaFinal: fin,
                      aulaId: 'Casa',
                      creadaPor: familiar.id,
                      alumnoIds: [alumnoId],
                    );
                    await _tareaRepo.guardarTarea(nueva);
                  }

                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          esEdicion
                              ? 'Tarea actualizada en la agenda del estudiante.'
                              : 'Tarea doméstica añadida a la agenda.',
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmarBorrado(Usuario familiar, Tarea tarea) async {
    if (tarea.creadaPor != familiar.id) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar tarea familiar'),
        content: Text(
          '¿Seguro que deseas eliminar "${tarea.nombre}" de la agenda?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _tareaRepo.eliminarTarea(tarea.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarea familiar eliminada.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final familiar = auth.usuario!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Panel Familiar · Hola, ${familiar.nombre}'),
        actions: [
          TextButton.icon(
            onPressed: auth.cerrarSesion,
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
          ),
        ],
      ),
      floatingActionButton: _alumnoSeleccionadoId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _abrirFormularioTarea(
                familiar: familiar,
                alumnoId: _alumnoSeleccionadoId!,
              ),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Añadir tarea en casa'),
            ),
      body: _cargandoAlumnos
          ? const Center(child: CircularProgressIndicator())
          : _alumnosAsignados.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.family_restroom,
                      size: 56,
                      color: AppColors.textSoft,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No tienes ningún alumno asignado a tu cuenta.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Contacta con la administración del colegio para que vinculen tu cuenta con el estudiante.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSoft),
                    ),
                  ],
                ),
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.child_care,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Agenda de:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 10),
                            // Si solo tiene 1 hijo asignado, muestra su nombre fijo;
                            // si tiene varios, muestra el desplegable solo con ellos.
                            if (_alumnosAsignados.length == 1)
                              Text(
                                _alumnosAsignados.first.nombre,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              )
                            else
                              DropdownButton<String>(
                                value: _alumnoSeleccionadoId,
                                underline: const SizedBox(),
                                items: _alumnosAsignados
                                    .map(
                                      (a) => DropdownMenuItem(
                                        value: a.id,
                                        child: Text(
                                          a.nombre,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) =>
                                    setState(() => _alumnoSeleccionadoId = val),
                              ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: () => _cambiarDia(-1),
                            ),
                            InkWell(
                              onTap: _seleccionarFecha,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                child: Text(
                                  '${_fechaSeleccionada.day.toString().padLeft(2, '0')}/${_fechaSeleccionada.month.toString().padLeft(2, '0')}/${_fechaSeleccionada.year}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () => _cambiarDia(1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: StreamBuilder<List<Tarea>>(
                          stream: _tareaRepo.streamTareasAlumno(
                            _alumnoSeleccionadoId!,
                            _fechaSeleccionada,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            final tareas = snapshot.data ?? [];
                            if (tareas.isEmpty) {
                              return const Center(
                                child: Text(
                                  'No hay actividades programadas para este día.',
                                  style: TextStyle(color: AppColors.textSoft),
                                ),
                              );
                            }

                            return ListView.separated(
                              itemCount: tareas.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final t = tareas[index];
                                final esTareaPropia =
                                    t.creadaPor == familiar.id;

                                return Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: esTareaPropia
                                        ? AppColors.greenSoft
                                        : AppColors.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: esTareaPropia
                                          ? AppColors.greenDark
                                          : AppColors.divider,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: esTareaPropia
                                              ? AppColors.greenDark
                                              : AppColors.primary,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          '${Tarea.hhmm(t.horaInicio)} - ${Tarea.hhmm(t.horaFinal)}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    t.nombre,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: esTareaPropia
                                                        ? Colors.white
                                                        : AppColors.cardBlue,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    esTareaPropia
                                                        ? 'Casa (Editable)'
                                                        : 'Colegio (Solo lectura)',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: esTareaPropia
                                                          ? AppColors.greenDark
                                                          : AppColors.primary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (t.descripcion.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 4,
                                                ),
                                                child: Text(
                                                  t.descripcion,
                                                  style: const TextStyle(
                                                    color: AppColors.textSoft,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (esTareaPropia) ...[
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            color: AppColors.primary,
                                          ),
                                          tooltip: 'Editar tarea familiar',
                                          onPressed: () =>
                                              _abrirFormularioTarea(
                                                familiar: familiar,
                                                alumnoId:
                                                    _alumnoSeleccionadoId!,
                                                tareaExistente: t,
                                              ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.redAccent,
                                          ),
                                          tooltip: 'Eliminar tarea familiar',
                                          onPressed: () =>
                                              _confirmarBorrado(familiar, t),
                                        ),
                                      ] else
                                        const Tooltip(
                                          message:
                                              'Tarea escolar gestionada por el profesorado',
                                          child: Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Icon(
                                              Icons.lock_outline,
                                              color: AppColors.textSoft,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
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
