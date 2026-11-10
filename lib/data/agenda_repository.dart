import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/meal_item.dart';
import '../models/mood_option.dart';

/// Fuente de datos de la agenda.
///
/// Por ahora devuelve datos de ejemplo. Cuando conectéis Firebase, solo hay
/// que cambiar el cuerpo de estos métodos (Cloud Firestore) sin tocar el
/// ViewModel ni las vistas.

class AgendaRepository {
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
    MoodOption(
      id: 'contento',
      label: 'Contento',
      icon: Icons.sentiment_very_satisfied,
    ),
    MoodOption(
      id: 'tranquilo',
      label: 'Tranquilo',
      icon: Icons.sentiment_satisfied,
    ),
    MoodOption(
      id: 'preocupado',
      label: 'Preocupado',
      icon: Icons.sentiment_neutral,
    ),
    MoodOption(
      id: 'enfadado',
      label: 'Enfadado',
      icon: Icons.sentiment_very_dissatisfied,
    ),
    MoodOption(
      id: 'cansado',
      label: 'Cansado',
      icon: Icons.sentiment_dissatisfied,
    ),
  ];
}
