import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/meal_item.dart';
import '../models/mood_option.dart';
import '../models/routine_task.dart';

/// Fuente de datos de la agenda.
///
/// Por ahora devuelve datos de ejemplo. Cuando conectéis Firebase, solo hay
/// que cambiar el cuerpo de estos métodos (Cloud Firestore) sin tocar el
/// ViewModel ni las vistas.

class AgendaRepository {
  List<RoutineTask> getTasks() => const [
        RoutineTask(
          id: '1',
          time: '09:00',
          title: 'Asamblea matinal',
          subtitle: 'Saludos y calendario',
          icon: Icons.groups_outlined,
          iconColor: AppColors.primary,
          iconBackground: AppColors.badge,
          imageUrl: 'https://picsum.photos/400/200',
        ),
        RoutineTask(
          id: '2',
          time: '11:00',
          title: 'Recreo y patio',
          subtitle: 'Juego libre y descanso',
          icon: Icons.park_outlined,
          iconColor: AppColors.green,
          iconBackground: AppColors.greenSoft,
        ),
        RoutineTask(
          id: '3',
          time: '12:30',
          title: 'Taller de tareas',
          subtitle: 'Fichas y lectoescritura',
          icon: Icons.palette_outlined,
          iconColor: AppColors.orange,
          iconBackground: AppColors.orangeSoft,
        ),
        RoutineTask(
          id: '4',
          time: '14:00',
          title: 'Comedor y aseo',
          subtitle: 'Lavado y comida rica',
          icon: Icons.restaurant,
          iconColor: AppColors.primary,
          iconBackground: AppColors.badge,
        ),
      ];

  List<MealItem> getMeals() => const [
        MealItem(
          label: '1º PLATO',
          name: 'Lentejas con verduras',
          icon: Icons.restaurant_menu,
          iconColor: AppColors.orange,
          iconBackground: AppColors.orangeSoft,
        ),
        MealItem(
          label: '2º PLATO',
          name: 'Pechuga con patatas',
          icon: Icons.dinner_dining,
          iconColor: AppColors.primary,
          iconBackground: AppColors.badge,
        ),
        MealItem(
          label: 'POSTRE',
          name: 'Plátano de Canarias',
          icon: Icons.eco,
          iconColor: AppColors.green,
          iconBackground: AppColors.greenSoft,
        ),
      ];

  String getReminder() =>
      'Traer el estuche de colores y agua fresca para el patio.';

  List<MoodOption> getMoods() => const [
        MoodOption(id: 'contento', label: 'Contento', icon: Icons.sentiment_very_satisfied),
        MoodOption(id: 'tranquilo', label: 'Tranquilo', icon: Icons.sentiment_satisfied),
        MoodOption(id: 'preocupado', label: 'Preocupado', icon: Icons.sentiment_neutral),
        MoodOption(id: 'enfadado', label: 'Enfadado', icon: Icons.sentiment_very_dissatisfied),
        MoodOption(id: 'cansado', label: 'Cansado', icon: Icons.sentiment_dissatisfied),
      ];
}