import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart'; // Importante: extensión del tema
import '../../models/tarea.dart';
import '../../viewmodels/agenda_view_model.dart';
import 'barra_progreso_pausable.dart';
import 'pictograma_imagen.dart';

/// Horario del día: es la parte principal de la pantalla.
class RoutineSection extends StatefulWidget {
  const RoutineSection({super.key});

  @override
  State<RoutineSection> createState() => _RoutineSectionState();
}

class _RoutineSectionState extends State<RoutineSection> {
  static const _altoTarjeta = 150.0;
  static const _separacion = 12.0;

  static const _etiquetas = {
    FiltroTareas.todas: 'Todas',
    FiltroTareas.actuales: 'Actuales',
    FiltroTareas.pendientes: 'Pendientes',
    FiltroTareas.completadas: 'Completadas',
  };

  static const _vacios = {
    FiltroTareas.todas: 'Hoy no tienes tareas.',
    FiltroTareas.actuales: 'Ahora no tienes ninguna tarea.',
    FiltroTareas.pendientes: '¡No te queda nada pendiente!',
    FiltroTareas.completadas: 'Todavía no has completado ninguna tarea.',
  };

  final _scroll = ScrollController();
  FiltroTareas? _filtroDesplazado;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Lleva la lista hasta la tarea actual (una vez por filtro).
  void _irATareaActual(List<Tarea> tareas, AgendaViewModel vm) {
    if (_filtroDesplazado == vm.filtro) return;
    final i = tareas.indexWhere(vm.esActual);
    if (i == -1) return;
    _filtroDesplazado = vm.filtro;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final destino = (i * (_altoTarjeta + _separacion)).clamp(
        0.0,
        _scroll.position.maxScrollExtent,
      );
      _scroll.animateTo(
        destino,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AgendaViewModel>();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.palette.surface, // Cambio dinámico
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: context.palette.primary, size: 32), // Sin const, color dinámico
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Mi horario',
                  style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: context.palette.textDark), // Sin const
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: context.palette.badge, // Cambio dinámico
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${vm.completedCount}/${vm.totalCount}',
                  style: TextStyle( // Sin const
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: context.palette.primary, // Cambio dinámico
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final f in FiltroTareas.values) ...[
                  ChoiceChip(
                    label: Text(_etiquetas[f]!),
                    labelStyle: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: vm.filtro == f
                          ? Colors.white
                          : context.palette.textDark, // Cambio dinámico
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    selected: vm.filtro == f,
                    selectedColor: context.palette.primary, // Cambio dinámico
                    showCheckmark: false,
                    onSelected: (_) => vm.setFiltro(f),
                  ),
                  const SizedBox(width: 10),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(child: _contenido(vm, context)), // Pasamos context para usar en _contenido
        ],
      ),
    );
  }

  Widget _contenido(AgendaViewModel vm, BuildContext context) {
    if (vm.error != null && vm.totalCount == 0) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              vm.error!,
              style: TextStyle(fontSize: 18, color: context.palette.textSoft), // Cambio dinámico sin const
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: vm.clearError,
              child: const Text('Reintentar', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      );
    }

    final tareas = vm.tasks;
    if (tareas.isEmpty) {
      return Center(
        child: Text(
          _vacios[vm.filtro]!,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, color: context.palette.textSoft), // Cambio dinámico sin const
        ),
      );
    }

    _irATareaActual(tareas, vm);

    return ListView.separated(
      controller: _scroll,
      itemCount: tareas.length,
      separatorBuilder: (_, _) => const SizedBox(height: _separacion),
      itemBuilder: (context, i) {
        final t = tareas[i];
        return ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _altoTarjeta),
          child: _TareaCard(
            tarea: t,
            actual: vm.esActual(t),
            completada: vm.esCompletada(t),
            onToggle: () => vm.toggleTask(t.id),
            onAudio: t.audioUrl == null
                ? null
                : () => vm.playTaskAudio(t.audioUrl!),
          ),
        );
      },
    );
  }
}

class _TareaCard extends StatelessWidget {
  const _TareaCard({
    required this.tarea,
    required this.actual,
    required this.completada,
    required this.onToggle,
    this.onAudio,
  });

  final Tarea tarea;
  final bool actual;
  final bool completada;
  final VoidCallback onToggle;
  final VoidCallback? onAudio;

  static String _hora(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final url = tarea.pictogramas.isNotEmpty
        ? tarea.pictogramas.first.urlResuelta
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: actual
            ? context.palette.cardTint // Cambio dinámico (antes cardBlue)
            : completada
                ? context.palette.background // Cambio dinámico
                : context.palette.surface, // Cambio dinámico
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: actual ? context.palette.primary : context.palette.divider, // Cambio dinámico
          width: actual ? 4 : 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              PictogramaImagen(
                url: url,
                id: tarea.pictogramaId,
                consulta: tarea.nombre,
                size: 118,
                iconoReserva: Icons.event_note_outlined,
                opacidad: completada ? 0.5 : 1,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${_hora(tarea.horaInicio)} - ${_hora(tarea.horaFinal)}',
                          style: TextStyle( // Sin const
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                            color: context.palette.primary, // Cambio dinámico
                          ),
                        ),
                        if (actual) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: context.palette.primary, // Cambio dinámico
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'AHORA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      tarea.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: completada
                            ? context.palette.textSoft // Cambio dinámico
                            : context.palette.textDark, // Cambio dinámico
                      ),
                    ),
                    if (tarea.descripcion.isNotEmpty)
                      Text(
                        tarea.descripcion,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle( // Sin const
                          fontSize: 20,
                          color: context.palette.textSoft, // Cambio dinámico
                        ),
                      ),
                  ],
                ),
              ),
              if (onAudio != null)
                IconButton(
                  tooltip: 'Escuchar',
                  iconSize: 34,
                  icon: const Icon(Icons.volume_up_outlined),
                  onPressed: onAudio,
                ),
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label: completada
                    ? 'Marcar como pendiente'
                    : 'Marcar como hecha',
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onToggle,
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: completada
                          ? context.palette.green // Cambio dinámico
                          : context.palette.checkEmpty, // Cambio dinámico
                    ),
                    child: Icon(
                      Icons.check,
                      color: completada ? Colors.white : context.palette.surface, // Cambio dinámico
                      size: 52,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Barra de progreso pausable (HU 17) en la tarea en curso
          if (actual && !completada) BarraProgresoPausable(tarea: tarea),
        ],
      ),
    );
  }
}