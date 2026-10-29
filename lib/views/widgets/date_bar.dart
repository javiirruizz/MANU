import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../viewmodels/agenda_view_model.dart';

/// Barra con el día, la fecha, la estación y los botones Mañana/Tarde/Escuchar.
class DateBar extends StatelessWidget {
  const DateBar({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AgendaViewModel>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _Chip(
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    vm.weekdayInitial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vm.weekdayName,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    Text(vm.dayNote,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSoft)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _Chip(
            child: Row(
              children: [
                Text('${vm.dayNumber}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 26)),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vm.monthName,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    Text('${vm.year}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSoft)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const Icon(Icons.filter_drama_outlined, color: AppColors.primary, size: 22),
          const SizedBox(width: 6),
          Text(vm.season, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.tabTrack,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _PeriodButton(
                  icon: Icons.wb_sunny_outlined,
                  label: 'Mañana',
                  selected: vm.period == AgendaPeriod.morning,
                  onTap: () => vm.setPeriod(AgendaPeriod.morning),
                ),
                _PeriodButton(
                  icon: Icons.filter_drama_outlined,
                  label: 'Tarde',
                  selected: vm.period == AgendaPeriod.afternoon,
                  onTap: () => vm.setPeriod(AgendaPeriod.afternoon),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: vm.readAloud,
            icon: const Icon(Icons.volume_up_outlined, size: 20),
            label: const Text('Escuchar',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.greenLight,
              foregroundColor: AppColors.greenDark,
              minimumSize: const Size(0, 46),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.chip,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class _PeriodButton extends StatelessWidget {
  const _PeriodButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : AppColors.textDark;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
