import 'dart:async';

import 'package:flutter/material.dart';

import '../data/agenda_repository.dart';
import '../data/tarea_repository.dart';
import '../models/meal_item.dart';
import '../models/mood_option.dart';
import '../models/routine_task.dart';
import '../models/tarea.dart';
import '../data/audio_service.dart';
import '../core/app_colors.dart';
import '../data/notification_service.dart';

enum AgendaPeriod { morning, afternoon }

/// Estado y lógica de la pantalla "Día a día".
/// La vista solo lee de aquí y llama a sus métodos; no tiene lógica propia.
class AgendaViewModel extends ChangeNotifier {
  AgendaViewModel(
    AgendaRepository repository,
    this._tareaRepository,
    this._notificaciones, {
    DateTime? today,
  }) : _today = today ?? DateTime.now(),
       _meals = repository.getMeals(),
       _moods = repository.getMoods(),
       _reminder = repository.getReminder();

  static const _weekdays = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];
  static const _months = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  static const _estilos = [
    (AppColors.primary, AppColors.badge),
    (AppColors.green, AppColors.greenSoft),
    (AppColors.orange, AppColors.orangeSoft),
  ];

  final AudioService _audioService = AudioService();
  final TareaRepository _tareaRepository;
  final NotificationService _notificaciones;

  final DateTime _today;
  final List<MealItem> _meals;
  final List<MoodOption> _moods;
  final String _reminder;

  StreamSubscription<List<Tarea>>? _sub;
  String? _alumnoId;
  List<RoutineTask> _tasks = [];

  String? _selectedMoodId;
  AgendaPeriod _period = AgendaPeriod.morning;
  bool _dayCompleted = false;
  String? _error;

  // ---- Sesión del alumno ----
  /// Se llama cuando cambia el usuario logueado (null = nadie / no es alumno).
  void setAlumno(String? alumnoId) {
    if (alumnoId == _alumnoId) return;
    _alumnoId = alumnoId;
    _sub?.cancel();
    _sub = null;
    _tasks = [];
    _notificaciones.cancelarTodos();

    if (alumnoId != null) {
      _sub = _tareaRepository
          .streamTareasAlumnoDesde(alumnoId, _today)
          .listen(
            _onTareas,
            onError: (Object e) {
              _error = 'No se pudieron cargar las tareas.';
              notifyListeners();
            },
          );
    }
    notifyListeners();
  }

  void _onTareas(List<Tarea> todas) {
    final alumnoId = _alumnoId;
    if (alumnoId == null) return;

    // Agenda: solo las de hoy.
    final hoy = todas.where((t) => _mismoDia(t.fecha, _today)).toList();
    _tasks = [
      for (var i = 0; i < hoy.length; i++) _aRoutineTask(hoy[i], i, alumnoId),
    ];

    // Avisos (HU 16): todas las futuras que aún no ha completado.
    _notificaciones.reprogramar(
      todas.where((t) => !t.estaCompletadaPor(alumnoId)).toList(),
    );
    notifyListeners();
  }

  RoutineTask _aRoutineTask(Tarea t, int i, String alumnoId) {
    final (color, fondo) = _estilos[i % _estilos.length];
    return RoutineTask(
      id: t.id,
      time: Tarea.hhmm(t.horaInicio),
      endTime: Tarea.hhmm(t.horaFinal),
      duration: t.duracionTexto,
      title: t.nombre,
      subtitle: t.descripcion,
      icon: Icons.event_note_outlined,
      iconColor: color,
      iconBackground: fondo,
      completed: t.estaCompletadaPor(alumnoId),
      imageUrl: t.imagenAdjuntaUrl,
      audioUrl: t.audioUrl,
    );
  }

  static bool _mismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ---- Datos para la vista ----
  List<RoutineTask> get tasks => List.unmodifiable(_tasks);
  List<MealItem> get meals => List.unmodifiable(_meals);
  List<MoodOption> get moods => List.unmodifiable(_moods);
  String get reminder => _reminder;
  String? get error => _error;

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

  /// HU 20: "Tarea terminada". Suena el refuerzo al instante y se guarda en
  /// Firestore; el stream devuelve la tarea ya como completada y el panel del
  /// profesor se entera por su propio stream.
  void completarTarea(String id) {
    final alumnoId = _alumnoId;
    if (alumnoId == null) return;

    _audioService.reproducirExito();
    _tareaRepository.marcarCompletada(id, alumnoId).catchError((Object e) {
      _error = 'No se pudo guardar que has terminado la tarea.';
      notifyListeners();
    });
  }

  /// Compatibilidad con la vista actual, que llama a toggleTask.
  void toggleTask(String id) {
    final alumnoId = _alumnoId;
    if (alumnoId == null) return;
    final yaCompletada = _tasks.any((t) => t.id == id && t.completed);
    if (yaCompletada) {
      _tareaRepository.desmarcarCompletada(id, alumnoId);
    } else {
      completarTarea(id);
    }
  }

  void clearError() {
    _error = null;
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

  // NOTA: para que los audios alojados en Firebase suenen en web, quien
  // administre Firebase debe configurar las reglas CORS en Google Cloud.
  void readAloud([String? text]) {
    final textoALeer =
        text ??
        'Rutina del día. Tienes ${totalCount - completedCount} tareas pendientes.';
    _audioService.leerTexto(textoALeer);
  }

  void playTaskAudio(String url) {
    _audioService.reproducirAudio(url);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
