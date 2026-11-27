import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart'; // Importante
import '../../core/tamanos.dart';
import '../../viewmodels/agenda_view_model.dart';
import 'pictograma_imagen.dart';

/// La fecha de hoy en un solo recuadro con su pictograma
/// y los botones de mañana y tarde.
class DateBar extends StatelessWidget {
  const DateBar({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AgendaViewModel>();
    final picto = context.medida(60);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: context.palette.surface, // Cambio dinámico
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          // Un único recuadro con la fecha de hoy
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: _Bloque(
                picto: PictogramaImagen(
                  consulta: 'calendario',
                  size: picto,
                  iconoReserva: Icons.calendar_month,
                ),
                titulo:
                    '${vm.weekdayName} ${vm.dayNumber} de ${vm.monthName.toLowerCase()}',
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: context.palette.tabTrack, // Cambio dinámico
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
        ],
      ),
    );
  }
}

class _Bloque extends StatelessWidget {
  const _Bloque({required this.picto, required this.titulo});

  final Widget picto;
  final String titulo;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
      decoration: BoxDecoration(
        // En los temas de varios colores lleva el primer color pastel
        color: p.acentos.isEmpty ? p.chip : p.acento(0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          picto,
          const SizedBox(width: 14),
          Text(
            titulo,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: context.letra(Letra.destacado),
              color: p.textDark,
            ),
          ),
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
    final color = selected
        ? Colors.white
        : context.palette.textDark; // Cambio dinámico
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected
            ? context.palette.primary
            : Colors.transparent, // Cambio dinámico
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: context.medida(26), color: color),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: context.letra(Letra.normal),
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
