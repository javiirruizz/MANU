import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../models/mood_option.dart';
import '../../viewmodels/agenda_view_model.dart';
import 'pictograma_imagen.dart';
import 'section_card.dart';

/// "¿Cómo me siento?": una emoción con su pictograma y el botón de fin de día.
class MoodSection extends StatelessWidget {
  const MoodSection({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AgendaViewModel>();

    return SectionCard(
      icon: Icons.favorite_border,
      title: '¿CÓMO ME SIENTO?',
      expand: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, c) {
              const hueco = 10.0;
              final ancho = (c.maxWidth - hueco * 2) / 3;
              return Wrap(
                spacing: hueco,
                runSpacing: hueco,
                children: [
                  for (final mood in vm.moods)
                    SizedBox(
                      width: ancho,
                      child: _MoodTile(
                        option: mood,
                        selected: vm.selectedMoodId == mood.id,
                        onTap: () => vm.selectMood(mood.id),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () {
              vm.completeDay();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('¡Día completado! Buen trabajo')),
              );
            },
            icon: const Icon(Icons.check_circle_outline, size: 28),
            label: const Text(
              '¡DÍA COMPLETADO!',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.greenDark,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(76),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodTile extends StatelessWidget {
  const _MoodTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final MoodOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(
        color: selected ? AppColors.green : Colors.transparent,
        width: 3,
      ),
    );

    return LayoutBuilder(
      builder: (context, c) {
        final lado = c.maxWidth - 20;
        final picto = lado < 112 ? lado : 112.0;
        return Semantics(
          button: true,
          selected: selected,
          label: option.label,
          excludeSemantics: true,
          child: Material(
            color: selected ? AppColors.selectedBg : AppColors.cardBlue,
            shape: forma,
            child: InkWell(
              customBorder: forma,
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 14,
                ),
                child: Column(
                  children: [
                    PictogramaImagen(
                      consulta: option.label.toLowerCase(),
                      size: picto,
                      iconoReserva: option.icon,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      option.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 19,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
