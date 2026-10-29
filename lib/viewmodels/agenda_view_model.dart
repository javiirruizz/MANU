import 'package:flutter/foundation.dart';
import '../data/agenda_repository.dart';
import '../models/meal_item.dart';
import '../models/mood_option.dart';
import '../models/routine_task.dart';

enum AgendaPeriod { morning, afternoon }

/// Estado y lógica de la pantalla "Día a día".
/// La vista solo lee de aquí y llama a sus métodos; no tiene lógica propia.
class AgendaViewModel extends ChangeNotifier {
  AgendaViewModel(AgendaRepository repository, {DateTime? today})
      : _today = today ?? DateTime.now(),
        _tasks = repository.getTasks(),
        _meals = repository.getMeals(),
        _moods = repository.getMoods(),
        _reminder = repository.getReminder();

  static const _weekdays = [
    'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
  ];
  static const _months = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  final DateTime _today;
  List<RoutineTask> _tasks;
  final List<MealItem> _meals;
  final List<MoodOption> _moods;
  final String _reminder;

  String? _selectedMoodId;
  AgendaPeriod _period = AgendaPeriod.morning;
  bool _dayCompleted = false;

  // ---- Datos para la vista ----
  List<RoutineTask> get tasks => List.unmodifiable(_tasks);
  List<MealItem> get meals => List.unmodifiable(_meals);
  List<MoodOption> get moods => List.unmodifiable(_moods);
  String get reminder => _reminder;

  int get totalCount => _tasks.length;
  int get completedCount => _tasks.where((t) => t.completed).length;

  String? get selectedMoodId => _selectedMoodId;
  AgendaPeriod get period => _period;
  bool get dayCompleted => _dayCompleted;

  // ---- Fecha ----
  String get weekdayName => _weekdays[_today.weekday - 1];
  String get weekdayInitial => weekdayName[0];
  int get dayNumber => _today.day;
  String get monthName => _months[_today.month - 1];
  int get year => _today.year;

  String get dayNote {
    switch (_today.weekday) {
      case DateTime.monday:
        return 'Día de inicio';
      case DateTime.friday:
        return 'Último día';
      default:
        return 'Hoy';
    }
  }

  String get season {
    final m = _today.month;
    if (m == 12 || m <= 2) return 'Invierno';
    if (m <= 5) return 'Primavera';
    if (m <= 8) return 'Verano';
    return 'Otoño';
  }

  // ---- Acciones ----
  void toggleTask(String id) {
    _tasks = [
      for (final t in _tasks) t.id == id ? t.copyWith(completed: !t.completed) : t
    ];
    notifyListeners();
  }

  void selectMood(String id) {
    _selectedMoodId = id;
    notifyListeners();
  }

  void setPeriod(AgendaPeriod period) {
    // TODO: filtrar las tareas por mañana/tarde cuando se defina el criterio.
    _period = period;
    notifyListeners();
  }

  void completeDay() {
    // TODO: guardar el registro del día y el estado de ánimo en Firestore.
    _dayCompleted = true;
    notifyListeners();
  }

  void readAloud() {
    // TODO: leer la pantalla en voz alta (paquete flutter_tts).
  }
}
