import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../models/routine_task.dart';
import '../../viewmodels/agenda_view_model.dart';
import 'section_card.dart';

/// Columna "Rutina del día".
class RoutineSection extends StatelessWidget {
  const RoutineSection({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AgendaViewModel>();

    if (vm.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final msg = vm.error;
        if (msg == null || !context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
        vm.clearError();
      });
    }

    return SectionCard(
      icon: Icons.access_time,
      title: 'RUTINA DEL DÍA',
      badge: '${vm.completedCount} de ${vm.totalCount}',
      child: vm.tasks.isEmpty
          ? const Center(
              child: Text(
                'Hoy no tienes tareas.',
                style: TextStyle(fontSize: 16, color: AppColors.textSoft),
              ),
            )
          : ListView.separated(
              itemCount: vm.tasks.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final task = vm.tasks[i];
                return _TaskTile(
                  task: task,
                  onComplete: () => vm.completarTarea(task.id),
                );
              },
            ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task, required this.onComplete});

  final RoutineTask task;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: task.completed ? AppColors.greenSoft : AppColors.cardBlue,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 15,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    task.time,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: task.iconBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(task.icon, color: task.iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Texto principal: se lee como un solo bloque.
                  Semantics(
                    container: true,
                    excludeSemantics: true,
                    label:
                        '${task.timeRange}${task.duration != null ? ", dura ${task.duration}" : ""}. '
                        '${task.title}. ${task.subtitle}. '
                        '${task.completed ? "Hecha" : "Pendiente"}',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // HU 16: tramo horario y duración en texto
                        Text(
                          task.duration != null
                              ? '${task.timeRange} · ${task.duration}'
                              : task.timeRange,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        if (task.subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            task.subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSoft,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Imagen adjunta (HU 08.1) + apoyos de audio (HU 18):
                  // se queda igual que lo tenías.
                  if (task.imageUrl != null && task.imageUrl!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => Dialog(
                            backgroundColor: Colors.transparent,
                            insetPadding: const EdgeInsets.all(10),
                            child: InteractiveViewer(
                              child: Image.network(task.imageUrl!),
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          task.imageUrl!,
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.record_voice_over,
                            color: AppColors.primary,
                          ),
                          onPressed: () {
                            context.read<AgendaViewModel>().readAloud(
                              "${task.title}. ${task.subtitle}",
                            );
                          },
                          tooltip: 'Leer instrucciones',
                        ),
                        if (task.audioUrl != null && task.audioUrl!.isNotEmpty)
                          IconButton(
                            icon: const Icon(
                              Icons.play_circle_fill,
                              color: AppColors.primary,
                            ),
                            onPressed: () {
                              context.read<AgendaViewModel>().playTaskAudio(
                                task.audioUrl!,
                              );
                            },
                            tooltip: 'Reproducir grabación',
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),

            if (task.completed)
              Semantics(
                label: 'Tarea hecha',
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 28),
                ),
              )
            else
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: onComplete,
                  icon: const Icon(Icons.check_circle_outline, size: 26),
                  label: const Text(
                    'Tarea terminada',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
