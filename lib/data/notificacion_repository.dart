import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/notificacion.dart';

class NotificacionService {
  NotificacionService({FirebaseFirestore? firestore})
    : _db =
          firestore ??
          (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null);

  final FirebaseFirestore? _db;

  /// Guarda y envía una notificación en Firestore.
  Future<void> guardarNotificacionEnBD(Notificacion notificacion) async {
    final db = _db;
    if (db == null) return;

    final col = db.collection('notificaciones');
    final docRef = notificacion.idNotificacion.isNotEmpty
        ? col.doc(notificacion.idNotificacion)
        : col.doc();

    notificacion.idNotificacion = docRef.id;
    await docRef.set(notificacion.toJson());
  }

  /// Escucha en tiempo real todas las notificaciones dirigidas a [idAlumno].
  Stream<List<Notificacion>> watchNotificacionesAlumno(String idAlumno) {
    final db = _db;
    if (db == null) return Stream.value(const []);

    return db
        .collection('notificaciones')
        .where('idAlumnos', arrayContains: idAlumno)
        .snapshots()
        .map((snap) {
      final lista = snap.docs
          .map((d) => Notificacion.fromMap(
                d.id,
                Map<String, dynamic>.from(d.data()),
              ))
          .toList()
        ..sort((a, b) => b.fecha.compareTo(a.fecha));
      return lista;
    });
  }

  /// Marca una notificación como leída/vista por [idAlumno].
  Future<void> marcarComoLeida(String idNotificacion, String idAlumno) async {
    final db = _db;
    if (db == null || idNotificacion.isEmpty || idAlumno.isEmpty) return;
    await db.collection('notificaciones').doc(idNotificacion).update({
      'leidaPor': FieldValue.arrayUnion([idAlumno]),
    });
  }

  /// Descarga puntual de las notificaciones de un alumno.
  Future<List<Notificacion>> cargarNotificacionesAlumno(String idAlumno) async {
    final db = _db;
    if (db == null) return const [];

    final snap = await db
        .collection('notificaciones')
        .where('idAlumnos', arrayContains: idAlumno)
        .get();
    final lista = snap.docs
        .map((d) => Notificacion.fromMap(
              d.id,
              Map<String, dynamic>.from(d.data()),
            ))
        .toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
    return lista;
  }
}