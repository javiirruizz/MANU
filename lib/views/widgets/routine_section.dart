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

    return SectionCard(
      icon: Icons.access_time,
      title: 'RUTINA DEL DÍA',
      badge: '${vm.completedCount} de ${vm.totalCount}',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final task in vm.tasks)
            _TaskTile(task: task, onTap: () => vm.toggleTask(task.id)),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task, required this.onTap});

  final RoutineTask task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          '${task.time}, ${task.title}, ${task.subtitle}. ${task.completed ? "Hecha" : "Pendiente"}',
      excludeSemantics: true,
      child: Material(
        color: AppColors.cardBlue,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time, size: 15, color: AppColors.primary),
                      const SizedBox(height: 2),
                      Text(task.time,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
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
                // Dentro de la clase _TaskTile, en el método build...
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.title,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(task.subtitle,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSoft)),
                      
                      // NUEVO: Renderizado de la imagen adjunta (HU 08.1)
                      if (task.imageUrl != null && task.imageUrl!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => Dialog(
                                backgroundColor: Colors.transparent, // Fondo invisible
                                insetPadding: const EdgeInsets.all(10), // Máximo tamaño posible
                                child: InteractiveViewer( // Permite hacer zoom con los dedos
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

                        // 2. Justo debajo del GestureDetector de la imagen, añade los botones de audio:
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.record_voice_over, color: AppColors.primary),
                              onPressed: () {
                                // Aquí llamaremos a la función del ViewModel
                                context.read<AgendaViewModel>().readAloud("${task.title}. ${task.subtitle}");
                              },
                              tooltip: 'Leer instrucciones',
                            ),
                            if (task.audioUrl != null && task.audioUrl!.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.play_circle_fill, color: AppColors.primary),
                                onPressed: () {
                                  context.read<AgendaViewModel>().playTaskAudio(task.audioUrl!);
                                },
                                tooltip: 'Reproducir grabación',
                              ),
                          ],
                        ),
                      ]
                    ],
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: task.completed ? AppColors.green : AppColors.checkEmpty,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: task.completed
                      ? const Icon(Icons.check, color: Colors.white, size: 22)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
