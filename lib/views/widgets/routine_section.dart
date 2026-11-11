import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../models/tarea.dart';
import '../../viewmodels/agenda_view_model.dart';
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, color: AppColors.primary, size: 32),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Mi horario',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.badge,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${vm.completedCount}/${vm.totalCount}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
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
                      color: vm.filtro == f ? Colors.white : AppColors.textDark,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    selected: vm.filtro == f,
                    selectedColor: AppColors.primary,
                    showCheckmark: false,
                    onSelected: (_) => vm.setFiltro(f),
                  ),
                  const SizedBox(width: 10),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(child: _contenido(vm)),
        ],
      ),
    );
  }

  Widget _contenido(AgendaViewModel vm) {
    if (vm.error != null && vm.totalCount == 0) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              vm.error!,
              style: const TextStyle(fontSize: 18, color: AppColors.textSoft),
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
          style: const TextStyle(fontSize: 22, color: AppColors.textSoft),
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
        return SizedBox(
          height: _altoTarjeta,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: actual
            ? AppColors.cardBlue
            : completada
            ? AppColors.background
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: actual ? AppColors.primary : AppColors.divider,
          width: actual ? 4 : 1.5,
        ),
      ),
      child: Row(
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
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
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
                          color: AppColors.primary,
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
                    color: completada ? AppColors.textSoft : AppColors.textDark,
                  ),
                ),
                if (tarea.descripcion.isNotEmpty)
                  Text(
                    tarea.descripcion,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      color: AppColors.textSoft,
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
            label: completada ? 'Marcar como pendiente' : 'Marcar como hecha',
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onToggle,
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: completada ? AppColors.green : AppColors.checkEmpty,
                ),
                child: Icon(
                  Icons.check,
                  color: completada ? Colors.white : AppColors.surface,
                  size: 52,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
