import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../models/tarea.dart';
import '../../viewmodels/agenda_view_model.dart';

class RoutineSection extends StatelessWidget {
  const RoutineSection({super.key});

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

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AgendaViewModel>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Mi rutina',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '${vm.completedCount}/${vm.totalCount}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Leer en voz alta',
                icon: const Icon(Icons.volume_up_outlined),
                onPressed: () => vm.readAloud(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final f in FiltroTareas.values) ...[
                  ChoiceChip(
                    label: Text(
                      _etiquetas[f]!,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    selected: vm.filtro == f,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: vm.filtro == f ? Colors.white : AppColors.textDark,
                    ),
                    showCheckmark: false,
                    onSelected: (_) => vm.setFiltro(f),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
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
            Text(vm.error!, style: const TextStyle(color: AppColors.textSoft)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: vm.clearError,
              child: const Text('Reintentar'),
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
          style: const TextStyle(fontSize: 18, color: AppColors.textSoft),
        ),
      );
    }

    return ListView.separated(
      itemCount: tareas.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final t = tareas[i];
        return _TareaCard(
          tarea: t,
          actual: vm.esActual(t),
          completada: vm.esCompletada(t),
          onToggle: () => vm.toggleTask(t.id),
          onAudio: t.audioUrl == null
              ? null
              : () => vm.playTaskAudio(t.audioUrl!),
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

  String? get _pictoUrl {
    if (tarea.pictogramas.isNotEmpty)
      return tarea.pictogramas.first.urlResuelta;
    final id = tarea.pictogramaId;
    if (id == null) return null;
    return 'https://static.arasaac.org/pictograms/$id/${id}_300.png';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: actual
            ? AppColors.cardBlue
            : completada
            ? AppColors.background
            : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: actual ? AppColors.primary : AppColors.divider,
          width: actual ? 3 : 1,
        ),
      ),
      child: Row(
        children: [
          _Pictograma(url: _pictoUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${_hora(tarea.horaInicio)} - ${_hora(tarea.horaFinal)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    if (actual) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'AHORA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  tarea.nombre,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: completada ? AppColors.textSoft : AppColors.textDark,
                  ),
                ),
                if (tarea.descripcion.isNotEmpty)
                  Text(
                    tarea.descripcion,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textSoft,
                    ),
                  ),
              ],
            ),
          ),
          if (onAudio != null)
            IconButton(
              tooltip: 'Escuchar',
              icon: const Icon(Icons.volume_up_outlined),
              onPressed: onAudio,
            ),
          const SizedBox(width: 4),
          Semantics(
            button: true,
            label: completada ? 'Marcar como pendiente' : 'Marcar como hecha',
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onToggle,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: completada ? AppColors.green : AppColors.checkEmpty,
                ),
                child: Icon(
                  Icons.check,
                  color: completada ? Colors.white : AppColors.surface,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pictograma extends StatelessWidget {
  const _Pictograma({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    const icono = Icon(
      Icons.event_note_outlined,
      color: AppColors.primary,
      size: 32,
    );
    return Container(
      width: 64,
      height: 64,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.badge,
        borderRadius: BorderRadius.circular(12),
      ),
      child: url == null
          ? icono
          : Image.network(
              url!,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => icono,
            ),
    );
  }
}
