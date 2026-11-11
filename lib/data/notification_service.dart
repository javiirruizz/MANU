import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/tarea.dart';

/// Avisa [minutosAntes] minutos antes de que empiece cada tarea,
/// también con la app cerrada (alarmas programadas en el sistema).
class NotificationService {
  static const int minutosAntes = 5;
  static const String _canalId = 'avisos_tareas';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _listo = false;
  Future<void> _cola = Future.value();

  bool get _soportado =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static const NotificationDetails _detalles = NotificationDetails(
    android: AndroidNotificationDetails(
      _canalId,
      'Avisos de tareas',
      channelDescription: 'Aviso suave antes de que empiece una tarea',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      enableVibration: false,
      playSound: true,
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<void> init() async {
    if (!_soportado) return;
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(), // pide permiso al iniciar
      ),
    );
    // Android 13+: permiso de notificaciones en tiempo de ejecución.
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    _listo = true;
  }

  /// Cancela todo y programa un aviso por cada tarea futura de [tareas].
  /// Se serializan las llamadas para que no se pisen entre sí.
  Future<void> reprogramar(List<Tarea> tareas) {
    _cola = _cola.then((_) => _reprogramar(tareas)).catchError((Object e) {
      debugPrint('Error programando avisos: $e');
    });
    return _cola;
  }

  Future<void> cancelarTodos() {
    _cola = _cola
        .then((_) async {
          if (_listo) await _plugin.cancelAll();
        })
        .catchError((Object e) {
          debugPrint('Error cancelando avisos: $e');
        });
    return _cola;
  }

  Future<void> _reprogramar(List<Tarea> tareas) async {
    if (!_listo) return;
    await _plugin.cancelAll();

    final ahora = DateTime.now();
    final modo = await _modoProgramacion();

    for (final t in tareas) {
      final aviso = t.horaInicio.subtract(
        const Duration(minutes: minutosAntes),
      );
      if (!aviso.isAfter(ahora)) continue;

      await _plugin.zonedSchedule(
        id: t.id.hashCode & 0x7fffffff,
        title: 'Pronto: ${t.nombre}',
        body: 'Empieza a las ${Tarea.hhmm(t.horaInicio)}',
        // Se programa un instante absoluto, por eso basta con UTC.
        scheduledDate: tz.TZDateTime.from(aviso, tz.UTC),
        notificationDetails: _detalles,
        androidScheduleMode: modo,
      );
    }
  }

  Future<AndroidScheduleMode> _modoProgramacion() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final exacto = await android?.canScheduleExactNotifications() ?? true;
    return exacto
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }
}
