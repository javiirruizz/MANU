import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../viewmodels/agenda_view_model.dart';
import 'pictograma_imagen.dart';

/// "Hoy es..." con día, fecha y estación, cada uno con su pictograma.
class DateBar extends StatelessWidget {
  const DateBar({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AgendaViewModel>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _Bloque(
                    picto: const PictogramaImagen(
                      consulta: 'semana',
                      size: 64,
                      iconoReserva: Icons.view_week_outlined,
                    ),
                    titulo: vm.weekdayName,
                    detalle: vm.dayNote,
                  ),
                  const SizedBox(width: 12),
                  _Bloque(
                    picto: const PictogramaImagen(
                      consulta: 'calendario',
                      size: 64,
                      iconoReserva: Icons.calendar_month,
                    ),
                    titulo: '${vm.dayNumber} de ${vm.monthName}',
                    detalle: '${vm.year}',
                  ),
                  const SizedBox(width: 12),
                  _Bloque(
                    picto: PictogramaImagen(
                      consulta: vm.season.toLowerCase(),
                      size: 64,
                      iconoReserva: Icons.filter_drama_outlined,
                    ),
                    titulo: vm.season,
                    detalle: 'Estación',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.tabTrack,
              borderRadius: BorderRadius.circular(16),
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
            icon: const Icon(Icons.volume_up_outlined, size: 28),
            label: const Text(
              'Escuchar',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.greenLight,
              foregroundColor: AppColors.greenDark,
              minimumSize: const Size(0, 64),
              padding: const EdgeInsets.symmetric(horizontal: 24),
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

class _Bloque extends StatelessWidget {
  const _Bloque({
    required this.picto,
    required this.titulo,
    required this.detalle,
  });

  final Widget picto;
  final String titulo;
  final String detalle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.chip,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          picto,
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                ),
              ),
              Text(
                detalle,
                style: const TextStyle(fontSize: 15, color: AppColors.textSoft),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
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
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Icon(icon, size: 24, color: color),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: color,
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
