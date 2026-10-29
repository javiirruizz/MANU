import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../models/mood_option.dart';
import '../../viewmodels/agenda_view_model.dart';
import 'section_card.dart';

/// Columna "Mi estado": cómo se siente el alumno y botón de fin de día.
class MoodSection extends StatelessWidget {
  const MoodSection({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AgendaViewModel>();

    return SectionCard(
      icon: Icons.favorite_border,
      title: 'MI ESTADO',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('¿Cómo te sientes en clase?', style: TextStyle(fontSize: 13)),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final mood in vm.moods)
                  _MoodTile(
                    option: mood,
                    selected: vm.selectedMoodId == mood.id,
                    onTap: () => vm.selectMood(mood.id),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () {
              vm.completeDay();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('¡Día completado! Buen trabajo')),
              );
            },
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('¡DÍA COMPLETADO!',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.greenDark,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodTile extends StatelessWidget {
  const _MoodTile({required this.option, required this.selected, required this.onTap});

  final MoodOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: option.label,
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.selectedBg : AppColors.cardBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? AppColors.green : Colors.transparent,
            width: 2,
          ),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(option.icon, color: AppColors.amber, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(option.label,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                ),
                if (selected)
                  const Icon(Icons.check_circle_outline, color: AppColors.textDark, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
