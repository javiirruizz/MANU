import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../models/meal_item.dart';
import '../../viewmodels/agenda_view_model.dart';
import 'pictograma_imagen.dart';
import 'section_card.dart';

/// Menú del comedor: compacto, con un pictograma por plato.
class MenuSection extends StatelessWidget {
  const MenuSection({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AgendaViewModel>();

    return SectionCard(
      icon: Icons.restaurant,
      title: 'MENÚ',
      badge: 'Hoy',
      expand: false,
      child: Column(
        children: [
          for (var i = 0; i < vm.meals.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _MealTile(meal: vm.meals[i]),
          ],
        ],
      ),
    );
  }
}

class _MealTile extends StatelessWidget {
  const _MealTile({required this.meal});
  final MealItem meal;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${meal.label}: ${meal.name}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: AppColors.cardBlue,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            PictogramaImagen(
              consulta: meal.pictograma ?? meal.name,
              size: 90,
              iconoReserva: meal.icon,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    meal.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 19,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
