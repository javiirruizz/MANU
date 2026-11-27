import 'dart:async';
import 'package:flutter/foundation.dart';

import '../data/agenda_repository.dart';
import '../data/audio_service.dart';
import '../data/notification_service.dart';
import '../data/tarea_repository.dart';
import '../models/meal_item.dart';
import '../models/mood_option.dart';
import '../models/tarea.dart';
import '../models/valoracion.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;

enum AgendaPeriod { morning, afternoon }

enum FiltroTareas { todas, actuales, pendientes, completadas }

/// Estado y lógica de la pantalla "Día a día".
class AgendaViewModel extends ChangeNotifier {
  AgendaViewModel({
    required this.alumnoId,
    required AgendaRepository repository,
    required TareaRepository tareaRepository,
    required NotificationService notificaciones,
    DateTime? today,
  }) : _tareaRepo = tareaRepository,
       _notificaciones = notificaciones,
       _now = today ?? DateTime.now(),
       _meals = repository.getMeals(),
       _moods = repository.getMoods(),
       _reminder = repository.getReminder() {
    // Reloj interno: cada minuto recalcula la tarea actual (Archivo 2)
    _reloj = Timer.periodic(const Duration(minutes: 1), (_) => _tick());
    _inicializarAgenda();
  }

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

  final String alumnoId;
  final TareaRepository _tareaRepo;
  final NotificationService _notificaciones;
  final AudioService _audioService = AudioService();

  late final Timer _reloj;
  StreamSubscription<List<Tarea>>? _sub;
  bool _disposed = false;

  DateTime _now;
  List<Tarea> _tareas = [];
  final List<MealItem> _meals;
  final List<MoodOption> _moods;
  final String _reminder;

  FiltroTareas _filtro = FiltroTareas.todas;
  AgendaPeriod _period = AgendaPeriod.morning;
  bool _dayCompleted = false;
  String? _error;
  String? _aviso;

  // ---- Datos para la vista ----
  List<Tarea> get tasks => List.unmodifiable(_tareas.where(_cumpleFiltro));
  List<MealItem> get meals => List.unmodifiable(_meals);
  List<MoodOption> get moods => List.unmodifiable(_moods);
  String get reminder => _reminder;
  String? get error => _error;

  int get totalCount => _tareas.length;
  int get completedCount => _tareas.where(esCompletada).length;

  FiltroTareas get filtro => _filtro;
  AgendaPeriod get period => _period;
  bool get dayCompleted => _dayCompleted;

  // ---- Estado de cada tarea ----
  bool esCompletada(Tarea t) => t.completadaPor.containsKey(alumnoId);

  bool esActual(Tarea t) =>
      !esCompletada(t) &&
      !_now.isBefore(t.horaInicio) &&
      _now.isBefore(t.horaFinal);

  bool esProxima(Tarea t) => !esCompletada(t) && t.horaInicio.isAfter(_now);

  bool _cumpleFiltro(Tarea t) => switch (_filtro) {
    FiltroTareas.todas => true,
    FiltroTareas.actuales => esActual(t),
    FiltroTareas.pendientes => !esCompletada(t),
    FiltroTareas.completadas => esCompletada(t),
  };

  static bool _mismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ---- Fecha ----
  String get weekdayName => _weekdays[_now.weekday - 1];
  String get weekdayInitial => weekdayName[0];
  int get dayNumber => _now.day;
  String get monthName => _months[_now.month - 1];
  int get year => _now.year;

  String get dayNote {
    switch (_now.weekday) {
      case DateTime.monday:
        return 'Día de inicio';
      case DateTime.friday:
        return 'Último día';
      default:
        return 'Hoy';
    }
  }

  String get season {
    final m = _now.month;
    if (m == 12 || m <= 2) return 'Invierno';
    if (m <= 5) return 'Primavera';
    if (m <= 8) return 'Verano';
    return 'Otoño';
  }

  Future<void> _inicializarAgenda() async {
    try {
      // Inicializar las notificaciones
      await _notificaciones.init();
    } catch (e) {
      debugPrint('Error al inicializar notificaciones: $e');
    }

    // Evitar continuar si se ha cerrado la pantalla
    if (_disposed) return;

    // Cargar las tareas cuando termine la inicialización
    _iniciarStream();
  }

  // ---- Carga (Stream) y Reloj ----
  void _iniciarStream() {
    _sub?.cancel();
    _sub = _tareaRepo
        .streamTareasAlumnoDesde(alumnoId, _now)
        .listen(
          _onTareas,
          onError: (Object e) {
            _error = 'No se pudieron cargar las tareas.';
            notifyListeners();
          },
        );
  }

  void _onTareas(List<Tarea> todas) {
    // 1. Filtrar solo las de hoy y ordenarlas
    final hoy = todas.where((t) => _mismoDia(t.fecha, _now)).toList();
    hoy.sort((a, b) => a.horaInicio.compareTo(b.horaInicio));
    _tareas = hoy;

    // 2. Programar notificaciones locales (Archivo 1)
    _notificaciones.reprogramar(
      _tareas.where((t) => !esCompletada(t)).toList(),
    );
    notifyListeners();
  }

  void _tick() {
    final antes = _now;
    _now = DateTime.now();
    if (antes.day != _now.day || antes.month != _now.month) {
      _iniciarStream(); // Si cambia el día, pedimos un stream nuevo
    } else {
      notifyListeners(); // Actualiza la UI para las tareas "actuales"
    }
  }

  // ---- Acciones ----
  void setFiltro(FiltroTareas filtro) {
    _filtro = filtro;
    notifyListeners();
  }

  /// Devuelve `true` si el cambio se ha guardado en el servidor.
  Future<bool> toggleTask(String id) async {
    final t = _tareas.where((t) => t.id == id).firstOrNull;
    if (t == null) return false;
    return marcarTarea(id, !esCompletada(t));
  }

  Future<bool> completarTarea(String id) => marcarTarea(id, true);

  Future<bool> marcarTarea(String id, bool completada) async {
    final i = _tareas.indexWhere((t) => t.id == id);
    if (i == -1) return false;
    final original = _tareas[i];

    // --- 1. Actualización optimista de la UI ---
    final mapa = {...original.completadaPor};
    if (completada) {
      mapa[alumnoId] = DateTime.now();
      _audioService.reproducirExito(); // Audio al instante
    } else {
      mapa.remove(alumnoId);
    }
    _tareas[i] = original.copyWith(completadaPor: mapa);
    notifyListeners();

    // --- 2. Enviar a servidor ---
    try {
      if (completada) {
        await _tareaRepo.marcarCompletada(id, alumnoId);
      } else {
        await _tareaRepo.desmarcarCompletada(id, alumnoId);
      }
      return true; // El stream confirmará el cambio
    } catch (e) {
      // Rollback visual si la petición falla, y aviso visible
      debugPrint('Error guardando tarea: $e');
      final j = _tareas.indexWhere((t) => t.id == id);
      if (j != -1) _tareas[j] = original;
      _avisar('No se ha podido guardar la tarea', e);
      return false;
    }
  }

  /// HU 22: guarda emoción y estrellas de una tarea terminada
  /// (y la deja completada en la misma escritura).
  Future<bool> guardarValoracion(
    String tareaId,
    String emocionId,
    int estrellas,
  ) async {
    final i = _tareas.indexWhere((t) => t.id == tareaId);
    if (i == -1) return false;
    final original = _tareas[i];
    _tareas[i] = original.copyWith(
      completadaPor: {
        ...original.completadaPor,
        alumnoId: original.completadaPor[alumnoId] ?? DateTime.now(),
      },
      valoraciones: {
        ...original.valoraciones,
        alumnoId: ValoracionTarea(
          emocionId: emocionId,
          estrellas: estrellas,
          fecha: DateTime.now(),
        ),
      },
    );
    notifyListeners();
    try {
      await _tareaRepo.guardarValoracion(
        tareaId: tareaId,
        alumnoId: alumnoId,
        emocionId: emocionId,
        estrellas: estrellas,
      );
      return true;
    } catch (e) {
      debugPrint('Error guardando valoración: $e');
      final j = _tareas.indexWhere((t) => t.id == tareaId);
      if (j != -1) _tareas[j] = original;
      _avisar('No se ha podido guardar cómo te has sentido', e);
      return false;
    }
  }

  /// Valoración del día completo (botón "¡Día completado!").
  Future<bool> guardarValoracionDia(String emocionId, int estrellas) async {
    try {
      await _tareaRepo.guardarValoracionDia(
        alumnoId: alumnoId,
        dia: _now,
        emocionId: emocionId,
        estrellas: estrellas,
      );
      _dayCompleted = true;
      _audioService.reproducirExito();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error guardando valoración del día: $e');
      _avisar('No se ha podido guardar cómo ha ido el día', e);
      return false;
    }
  }

  /// Mensaje puntual para mostrar en un SnackBar (se consume al leerlo).
  String? consumirAviso() {
    final a = _aviso;
    _aviso = null;
    return a;
  }

  void _avisar(String texto, Object e) {
    final codigo = e is FirebaseException ? e.code : null;
    _aviso = switch (codigo) {
      'permission-denied' =>
        '$texto: Firebase no da permiso al alumno (revisa las reglas de Firestore).',
      null => '$texto. Inténtalo otra vez.',
      _ => '$texto ($codigo). Inténtalo otra vez.',
    };
    notifyListeners();
  }

  void clearError() {
    _error = null;
    _iniciarStream();
    notifyListeners();
  }

  void setPeriod(AgendaPeriod period) {
    _period = period;
    notifyListeners();
  }

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
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    _reloj.cancel();
    _notificaciones.cancelarTodos(); // Limpieza al salir
    super.dispose();
  }
}
