import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart'; // Importante
import '../../core/tamanos.dart';
import '../../viewmodels/agenda_view_model.dart';
import 'pictograma_imagen.dart';

/// "Hoy es..." con día, fecha y estación, cada uno con su pictograma,
/// y los botones de mañana/tarde y escuchar.
class DateBar extends StatelessWidget {
  const DateBar({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AgendaViewModel>();
    final picto = context.medida(60);
    final altoBoton = context.medida(64);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: context.palette.surface, // Cambio dinámico
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  _Bloque(
                    picto: PictogramaImagen(
                      consulta: 'semana',
                      size: picto,
                      iconoReserva: Icons.view_week_outlined,
                    ),
                    titulo: vm.weekdayName,
                    detalle: vm.dayNote,
                  ),
                  const SizedBox(width: 12),
                  _Bloque(
                    picto: PictogramaImagen(
                      consulta: 'calendario',
                      size: picto,
                      iconoReserva: Icons.calendar_month,
                    ),
                    titulo: '${vm.dayNumber} de ${vm.monthName}',
                    detalle: '${vm.year}',
                  ),
                  const SizedBox(width: 12),
                  _Bloque(
                    picto: PictogramaImagen(
                      consulta: vm.season.toLowerCase(),
                      size: picto,
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
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: vm.readAloud,
            icon: Icon(Icons.volume_up_outlined, size: context.medida(30)),
            label: Text(
              'Escuchar',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: context.letra(Letra.normal),
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: context
                  .palette
                  .green, // Cambio dinámico (el verde que defina el tema)
              foregroundColor: context.palette.surface, // Cambio dinámico
              minimumSize: Size(0, altoBoton),
              padding: const EdgeInsets.symmetric(horizontal: 22),
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
        color: context.palette.chip, // Cambio dinámico
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
                style: TextStyle(
                  // Sin const
                  fontWeight: FontWeight.w800,
                  fontSize: context.letra(Letra.destacado),
                  color: context.palette.textDark, // Añadido color dinámico
                ),
              ),
              Text(
                detalle,
                style: TextStyle(
                  fontSize: context.letra(Letra.detalle),
                  color: context.palette.textSoft,
                ), // Cambio dinámico sin const
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
